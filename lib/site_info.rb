require 'json'
require 'pp'
require 'nokogiri'
require 'open-uri'

require 'open-uri'
def html_bytesize html
  begin
    doc = Nokogiri::HTML(html)
  rescue
    return
  end
  imgs = doc.xpath("//img")
  lengths = imgs.map do |img|
    url = img.attributes["src"].value or break
    sleep 0.1
    Thread.start(url) do |url|
      length = 0
      begin
        open(url) do |f|
          if l = f.meta["content-length"] then
            length = l.to_i
          else
            length = f.read.bytesize
          end
        end
      rescue
      end
      length
    end
  end
  lengths.inject(html.bytesize) do |sum, thread|
    length = 0
    sum += thread.value
  end
end

class SiteInfo
  def initialize
    load_siteinfo
  end

  def load_siteinfo
    filename = File.join(File.expand_path(File.dirname(__FILE__)),"items.yaml")
    return if @mtime && @mtime < File.mtime(filename)

    @mtime = File.mtime(filename)
    @siteinfos = YAML.load(open(filename))
  end

  def fetch_next_link uri, xpath, headers = []
    headers ||= []
    now = Time.now
#    logfilename = "#{now.strftime("%Y%m%d_%H%M%S")}_#{now.usec}.#{Thread.current.__id__}"
    basename = (rand(36**10)).to_s(36)
    logfilename  = File.join(RAILS_ROOT, "tmp", "q#{basename}.log")
    htmlfilename = File.join(RAILS_ROOT, "tmp", "q#{basename}.html")

    args = headers.map do |header|
      "--header=\"#{header.chomp}\""
    end.join(" ")

    cmd = "wget #{args} -O #{htmlfilename} -o #{logfilename} -k #{uri} 2> /dev/null"
    begin
      system cmd
      log = open(logfilename).read
      case log
      when /\`(.+)\' saved/
        htmlfilename = $1
        @doc = Nokogiri::HTML(open(htmlfilename).read)
      when /404 Not Found/
        raise "404 Not Found"
        htmlfilename = nil
      else
        raise "unexpected error #{log}"
      end
    ensure
      File.unlink logfilename
      File.unlink htmlfilename if htmlfilename
    end

    return unless xpath
    elem = @doc.xpath(xpath).first

    return nil unless elem
    href = elem.attributes["href"].value
    return uri + href
  end

  def get_siteinfo uri
    load_siteinfo

    @siteinfos.each do |si|
      next unless si["url"]
      next if si["url"].include?("https?")
      if Regexp.compile(si["url"]) =~ uri.to_s then
        return si
      end
    end
    return nil
  end

  def integrate_html url
    begin
      elems = prefetch_page url
      return "" if elems.nil?
      elems.map do |elem|
        "<div>#{elem}</div>"
      end.join("\n")
    rescue e
    end
  end

  def prefetch_page url
    uri = URI(url)

    if url.include?("http://www.nikkeibp.co.jp/article/news/") then
      uri = fetch_next_link(uri, "//div[@id='title']/h1/a") || uri
    end

    siteinfo = get_siteinfo url

    if siteinfo
      page_elem = siteinfo["pageElement"]
      next_link = siteinfo["nextLink"]
      headers   = siteinfo["headers"]
    else
      return
    end
    
    elems = []
    loop do
      nuri = fetch_next_link uri, next_link, headers
      length = 0
      @doc.xpath(page_elem).each do |elem|
        elems << elem
        length += elem.to_s.length
      end
      break unless nuri
      break if length > 70_000
      uri = nuri
    end
    return elems
  end
end


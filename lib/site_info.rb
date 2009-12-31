require 'json'
require 'pp'
require 'nokogiri'
require 'open-uri'

require 'open-uri'
def html_bytesize html
  doc = Nokogiri::HTML(html)
  imgs = doc.xpath("//img")
  lengths = imgs.map do |img|
    url = img.attributes["src"].value
    Thread.start(url) do |url|
      length = 0
      open(url) do |f|
        if l = f.meta["content-length"] then
          length = l.to_i
        else
          length = f.read.bytesize
        end
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
    filename = File.join(File.expand_path(File.dirname(__FILE__)),"items.yaml")
    @siteinfos = YAML.load(open(filename))
  end

  def fetch_next_link uri, xpath
    now = Time.now
    logfilename = "#{now.strftime("%d%H%M%S")}#{now.usec}"
    cmd = "wget -o #{logfilename} -k #{uri} 2> /dev/null"
    system cmd
    log = open(logfilename).read
    filename = log[/\`(.+)\' saved/, 1]
    @doc = Nokogiri::HTML(open(filename).read)
    File.unlink filename
    File.unlink logfilename

    return unless xpath

    elem = @doc.xpath(xpath).first
    return nil unless elem
    href = elem.attributes["href"].value
    return uri + href
  end

  def get_siteinfo uri
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
    elems = prefetch_page url
    return "" if elems.nil?
    elems.map do |elem|
      "<div>#{elem}</div>"
    end.join("\n")
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
    else
      return
    end
    
    elems = []
    loop do
      nuri = fetch_next_link uri, next_link
      length = 0
      @doc.xpath(page_elem).each do |elem|
        elems << elem
        length += elem.to_s.length
      end
      break unless nuri
      break if length > 700_000
      uri = nuri
    end
    return elems
  end
end


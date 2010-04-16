module MobileHelper
  DOCOMO_NUM = {
    0 => '&#63888;', 1 => '&#63879;', 2 => '&#63880;', 3 => '&#63881;',
    4 => '&#63882;', 5 => '&#63883;', 6 => '&#63884;', 7 => '&#63885;',
    8 => '&#63886;', 9 => '&#63887;', "*" => '*', "#" => "#"}
  AU_NUM = [325, 180, 181, 182, 183, 184, 185, 186, 187, 188]
  SOFTBANK_NUM = ['&#57893;', '&#57884;', '&#57885;',
    '&#57886;', '&#57887;', '&#57888;', '&#57889;',
    '&#57890;', '&#57891;', '&#57892;']

  def emoji_number num
    case request.mobile
    when Jpmobile::Mobile::Docomo
      DOCOMO_NUM[num]
    when Jpmobile::Mobile::Au
      %Q|<img localsrc="#{AU_NUM[num]}">| 
    when Jpmobile::Mobile::Softbank
      SOFTBANK_NUM[num]
    end
  end

  def number_link_to(num, title, path)
    return link_to(title, path) unless num
    case request.mobile
    when Jpmobile::Mobile::Docomo
      link = ""
      if path.size == 1 and anchor = path[:anchor] then
        link = "<a href=\"\##{anchor}\" accesskey=\"#{num}\">#{title}</a>"
      else
        link = link_to(title, path, :accesskey => num)
      end
      DOCOMO_NUM[num] + link
    when Jpmobile::Mobile::Au
      prelude = num.is_a? Integer ? %Q|<img localsrc="#{AU_NUM[num]}">| : num
      prelude + link_to(title, path, :accesskey => num)
    when Jpmobile::Mobile::Softbank
      prelude = num.is_a? Integer ? SOFTBANK_NUM[num] : num
      prelude + %Q|<a href="#{path}" DIRECTKEY="#{num}" NONUMBER>#{title}</a>|
    else
      link_to(title, path)
    end
  end

  def number_submit_tag(num, title)
    case request.mobile
    when Jpmobile::Mobile::Docomo
      DOCOMO_NUM[num] + submit_tag(title, :accesskey => num)
    when Jpmobile::Mobile::Au
      prelude = num.is_a? Integer ? %Q|<img localsrc="#{AU_NUM[num]}">| : num
      prelude + submit_tag(title, :accesskey => num)
    when Jpmobile::Mobile::Softbank
      prelude = num.is_a? Integer ? SOFTBANK_NUM[num] : num
      prelude + submit_tag(title, :directkey => num)
    else
      submit_tag(title)
    end
  end

  def twitter_oauth_consumer
    tw_secret = YAML::load(File.join(RAILS_ROOT, "config", "twitter.yaml"))
    consumer = OAuth::Consumer.new(
      tw_secret["consumer_key"],
      tw_secret["consumer_secret"],
      :site => 'http://twitter.com'
    )
    return consumer
  end

end

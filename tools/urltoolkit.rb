module UrlToolKit
  def expand_url(url)
    url = URI(url)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = 3
    http.read_timeout = 7
    http.start() {|http|
      response = http.head(url.request_uri)
      case response
      when Net::HTTPRedirection
        expand_url(response['location'])
      else
        return url
      end
      }
  end

  def get_thumb(url_str)
    url = expand_url(url_str)
    case url.host
    when "instagram.com"
      url.to_s+"media/?size=l"
    when "twitpic.com"
      "#{url.scheme}://twitpic.com/show/full/#{url.path.split("/")[1]}"
    when "img.ly"
      "#{url.scheme}://#{url.host}/show/full#{url.path}"
    when "lockerz.com"
      "http://api.plixi.com/api/TPAPI.svc/imagefromurl?size=big&url=" + url.to_s
    when "photozou.jp"
      "http://photozou.jp/p/img/#{url.path.split('/').last}"
    when /twipple.jp$/
      "http://p.twipple.jp/show/large/#{url.path.split('/').last}"
    when "movapic.com"
      "http://image.movapic.com/pic/m_#{url.path.split('/').last}.jpeg"
    else
      "http://img.simpleapi.net/small/#{url_str}"
    end
  end
end

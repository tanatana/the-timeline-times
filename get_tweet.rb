# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)
Bundler.require(:default)
require 'pp'
require "uri"
require 'database'
require 'tools/urltoolkit'
require 'oembed'
require 'nokogiri'
require 'nkf'
require 'net/https'

class Hash
  def rename(old_sym, new_sym)
    val = self.delete(old_sym)
    self[new_sym] = val
  end
end

CONSUMER_KEY, CONSUMER_SECRET = File.open("consumer.cfg").read.split("\n")

def consumer
  OAuth::Consumer.new(
                      CONSUMER_KEY,
                      CONSUMER_SECRET,
                      :site => "http://api.twitter.com")
end

User.all().each do |curr_user|
  next if curr_user.access_token == nil

  rubytter = OAuthRubytter.new(
               OAuth::AccessToken.new(
                                      consumer,
                                      curr_user.access_token,
                                      curr_user.access_secret))

  # 逆にしておかないと，DBに入れるときにエラーが起きた際の最新ツイートがおかしくなる
  tl = rubytter.home_timeline(:since_id => curr_user.latest_status_id, :count => 200, :include_entities => true).reverse
  # tl = rubytter.home_timeline(:count => 200, :include_entities => true).reverse

  tl.each do |status|
    if curr_user.latest_status_id < status.id
      curr_user.latest_status_id =  status.id
      curr_user.save
    else
      next
    end

    urls = status.entities.urls
    if !urls.empty?
      status.rename(:id, :status_id)
      status.rename(:id_str, :status_id_str)
      status.user.rename(:id, :user_id)
      status.user.rename(:id_str, :user_id_str)
      status[:created_at] = Time.parse(status.created_at)

      if mongo_status = Status.first(:status_id => status.id)
        next
      else
        mongo_status = Status.new(status)
        mongo_status.save
      end
      urls.each do |url|
        url.remove(:indices)
        begin
          expanded_url = UrlToolKit.expand_url(url.expanded_url).to_s
        rescue Timeout::Error, Errno::ECONNRESET, EOFError, Errno::ECONNREFUSED => e
          expanded_url = url.expanded_url.to_s
        end

        unless mongo_webpage = Webpage.first(:expanded_url => expanded_url)
          mongo_webpage = Webpage.create(:expanded_url => expanded_url)
          title = ''

          begin
            url = URI.parse(expanded_url)
            http = Net::HTTP.new(url.host, url.port)
            if url.port == 443
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end

            response = http.start{|io| io.get(url.request_uri)}
          rescue => e
            pp e
            response = nil
          end

          pp response['content-type']
          case response['content-type']
          when /text\/html/
            content = response.body
            if content and og = OpenGraph.parse(content)
              mongo_webpage.opengraph = og.to_hash
              title = og['title']
            elsif content
              doc = Nokogiri::HTML.parse(content)
              title = doc.css("title").text
            else
              title = "untitled"
            end

            begin
              embed = OEmbed::Providers::Embedly.get(expanded_url)
              mongo_webpage.embed = embed.html
            rescue OEmbed::NotFound, OEmbed::UnknownResponse
              mongo_webpage.thumb = UrlToolKit.get_thumb(expanded_url)
              # mongo_webpage.thumb = "http://fakeimg.pl/200x150/"
            end
            mongo_webpage.title = NKF.nkf("-w", title)
          when /image\/.*/
            mongo_webpage.title = "image"
            mongo_webpage.thumb = expanded_url
          end
          mongo_webpage.save
        end

        mongo_webpage.statuses << mongo_status
        mongo_webpage.save
        mongo_article = Article.find_or_initialize_by_user_id_and_webpage_id(curr_user.id, mongo_webpage.id)
        mongo_webpage.articles << mongo_article
        mongo_webpage.save
        mongo_article.statuses << mongo_status
        mongo_article.save

        # Article_in_dateクラスはひとつのUserと複数のAticleを持つ
        # UserのObjectIDと日付でその日にTL上で言及があったすべてのArticle_idが引けるようにする
        today = Time.now
        mongo_articles_in_dates = Articles_in_date.find_or_initialize_by_user_id_and_year_and_mon_and_day(curr_user.id, today.year, today.mon, today.day)
        # FIXME: 同じObjectIDがarticlesに無い場合のみ追加するように
        mongo_articles_in_dates.articles << mongo_article
        mongo_articles_in_dates.articles.uniq!
        mongo_articles_in_dates.save

        curr_user.articles << mongo_article
        curr_user.save
      end
      curr_user.save
    end
  end
end

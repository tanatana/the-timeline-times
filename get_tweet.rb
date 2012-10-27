# -*- coding: utf-8 -*-

$:.unshift File.dirname(__FILE__)
Bundler.require(:default)
require 'pp'
require "uri"
require 'model/status'
require 'model/user'
require 'model/webpage'
require 'model/article'
require 'tools/urltoolkit'
include UrlToolKit

class DocumentIsNOTExist < StandardError; end
class StatusIsEmpty < StandardError; end

class Hash
  def rename(old_sym, new_sym)
    val = self.delete(old_sym)
    self[new_sym] = val
  end
end

CONSUMER_KEY, CONSUMER_SECRET = File.open("consumer.cfg").read.split("\n")
MongoMapper.database = "tltimes"

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
  # うまく取得数が制限できない
  # latest_article = Article.first(:user_id => curr_user.id, :order => :updated_at.desc)
  # p latest_article
  # begin
  #   raise StatusIsEmpty until latest_article
  #   latest_status = latest_article.status_ids.first
  #   p latest_status_id = Status.find(latest_status).status_id
  #   tl = rubytter.home_timeline(:since_id => latest_status_id, :count => 200, :include_entities => true)
  # rescue StatusIsEmpty => e
  #   p e
  #   tl = rubytter.home_timeline(:count => 200, :include_entities => true)
  # end
  tl = rubytter.home_timeline(:count => 200, :include_entities => true)

  tl.each do |status|
    urls = status.entities.urls
    if !urls.empty?
      status.rename(:id, :status_id)
      status.rename(:id_str, :status_id_str)
      status.user.rename(:id, :user_id)
      status.user.rename(:id_str, :user_id_str)
      mongo_status = Status.find_or_initialize_by_status_id(status.id)
      mongo_status.save
      urls.each do |url|
        url.remove(:indices)
        begin
          mongo_webpage =  Webpage.first(:expanded_url => url.expanded_url)
          raise DocumentIsNOTExist if mongo_webpage == nil
          # TODO: make get_title(url), change this
          mongo_webpage.statuses << mongo_status
          p mongo_webpage.status_ids.size
          mongo_webpage.save
          mongo_article = Article.find_or_initialize_by_user_id_and_webpage_id(curr_user.id, mongo_webpage.id)
          mongo_webpage.articles << mongo_article
          mongo_webpage.save
          mongo_article.statuses << mongo_status
          mongo_article.save
          curr_user.articles << mongo_article
          curr_user.save
        rescue DocumentIsNOTExist
          mongo_webpage = Webpage.create(url)
          begin
            mongo_webpage.thumb = get_thumb(url.expanded_url)
          rescue Timeout::Error, Errno::ECONNRESET, EOFError, Errno::ECONNREFUSED => e
            p e
            mongo_webpage.thumb = "http://fakeimg.pl/200x150/"
          end
          mongo_webpage.title = "title"
          mongo_webpage.save
          retry
        end
      end
      curr_user.save
    end
  end
end

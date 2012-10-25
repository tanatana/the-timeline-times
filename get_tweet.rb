# -*- coding: utf-8 -*-

$:.unshift File.dirname(__FILE__)
Bundler.require(:default)
require 'pp'
require "uri"
require 'model/status'
require 'model/user'
require 'model/webpage'
require 'model/article'

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

def find_URLs(text)
  URI.extract(text, %w[http])
end


User.all().each do |curr_user|
  next if curr_user.access_token == nil

  rubytter = OAuthRubytter.new(
               OAuth::AccessToken.new(
                                      consumer,
                                      curr_user.access_token,
                                      curr_user.access_secret))

  
  latest_status = Status.first(:user_id => curr_user.id, :order => :created_at.desc)

  begin
    raise StatusIsEmpty until latest_status
    tl = rubytter.home_timeline(:since_id => latest_status.status_id, :count => 200, :include_entities => true)
  rescue StatusIsEmpty
    tl = rubytter.home_timeline(:count => 200, :include_entities => true)
  end

  tl.each do |status|
    urls = status.entities.urls
    if !urls.empty?
      status.rename(:id, :status_id)
      status.rename(:id_str, :status_id_str)
      status.user.rename(:id, :user_id)
      status.user.rename(:id_str, :user_id_str)
      mongo_status = Status.new(status)
      curr_user.statuses << mongo_status
      mongo_status.save
      urls.each do |url|
        mongo_webpage = Webpage.create(url)
        # TODO: make get_title(url), change this
        mongo_webpage.title = "title"
        mongo_webpage.statuses << mongo_status
        mongo_webpage.save
        mongo_article = Article.find_or_initialize_by_user_id_and_webpage_id(curr_user.id, mongo_webpage.id)
        mongo_webpage.article = mongo_article
        mongo_webpage.save
        mongo_article.statuses << mongo_status
        mongo_article.save
        curr_user.articles << mongo_article
        curr_user.save
      end
      curr_user.save
    end
  end
end

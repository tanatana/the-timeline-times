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
  
  latest_status = Status.first(:order => :posted_at.desc)
  
  begin
    raise StatusIsEmpty until latest_status 
    tl = rubytter.home_timeline(:since_id => latest_status.status_id, :count => 200, :include_entities => true)
  rescue StatusIsEmpty
    tl = rubytter.home_timeline(:count => 200, :include_entities => true)
  end

  tl.each do |status|
    if urls = status.entities.urls
      status_owner =  User.find_or_create_by_user_id(status.user.id)
      status_owner.screen_name = status.user.screen_name
      status_owner.name = status.user.name
      status_owner.profile_image_url = status.user.profile_image_url
      status_owner.save
    
      s = Status.find_or_create_by_status_id(status.id)
      s.creator = status_owner
      s.posted_at = status.created_at
      s.text = status.text
      s.save
      urls.each do |url|
        wp = Webpage.find_or_create_by_page_url(url.expanded_url)
        wp.statuses << s
        wp.user = curr_user
        wp.save
        curr_user.webpages << wp
      end
      curr_user.statuses << s
      curr_user.save
    end
    
  end
end

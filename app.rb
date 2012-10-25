# -*- coding: utf-8 -*-

$:.unshift File.dirname(__FILE__)
Bundler.require(:default, :web)
require 'pp'
require 'erb'
require 'model/status'
require 'model/user'
require 'model/webpage'
require 'model/article'

CONSUMER_KEY, CONSUMER_SECRET = File.open("consumer.cfg").read.split("\n")
MongoMapper.database = "tltimes"

class App < Sinatra::Base
  configure do
    include ERB::Util

    use Rack::Session::Cookie, :secret => "change me"
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end

  helpers do
    def consumer
      OAuth::Consumer.new(
                          CONSUMER_KEY,
                          CONSUMER_SECRET,
                          :site => "http://api.twitter.com")
    end
  end

  get '/' do
    erb :index
  end

  get '/oauth' do
    request_token = consumer.get_request_token(:oauth_callback => "http://localhost:9393/callback")
    session[:request_token] = request_token.token
    session[:request_secret] = request_token.secret
    redirect request_token.authorize_url
  end

  get '/callback' do
    request_token = OAuth::RequestToken.new(
                                            consumer,
                                            session[:request_token],
                                            session[:request_secret])
    access_token = request_token.get_access_token(
                                                  {},
                                                  :oauth_token => params[:oauth_token],
                                                  :oauth_verifier => params[:oauth_verifier])
    rubytter = OAuthRubytter.new(
             OAuth::AccessToken.new(
                 self.consumer,
                 access_token.token,
                 access_token.secret))
    # session[:access_token] = access_token.token
    # session[:access_secret] = access_token.secret
    curr_user =  rubytter.user(access_token.params[:user_id])
    mongo_user = User.find_or_create_by_user_id(curr_user.id)
    mongo_user.screen_name = curr_user.screen_name
    mongo_user.name = curr_user.name
    mongo_user.profile_image_url = curr_user.profile_image_url
    mongo_user.access_token = access_token.token
    mongo_user.access_secret= access_token.secret
    mongo_user.save

    session.delete(:request_token)
    session.delete(:request_secret)

    redirect "/users/#{curr_user.screen_name}/recent"
  end

  get '/users/:screen_name/recent' do
    u =  User.find_by_screen_name(params[:screen_name])
    # @webpages = Webpage.where(:user_id => u.id, :updated_at.gte => 1.days.ago).sort(:updated_at.desc)
    # @articles = Article.where(:user => u.id).sort(:updated_at.desc).limit(100)
    @articles = Article.where(:user_id => u.id).sort(:updated_at.desc).limit(100)
    @articles.each do |article|
      begin
        article.webpage.expanded_url
      rescue 
        p "help me!"
        p article.id
      end
    end
    
    
    erb :user_home
  end

  get '/users/:screen_name' do
    u =  User.find_by_screen_name(params[:screen_name])
    @webpages = Webpage.where(:user_id => u.id, :updated_at.gte => 1.days.ago).sort(:updated_at.desc)
    erb :user_home
  end


  get '/users/*/*/*/*/' do
    "Hello, #{params}"
  end
end

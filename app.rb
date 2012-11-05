# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)
Bundler.require(:default, :web)
require 'database'
require 'omniauth'
require 'time'
require 'pp'
require 'erb'

CONSUMER_KEY, CONSUMER_SECRET = File.open("consumer.cfg").read.split("\n")

class App < Sinatra::Base
  configure do
    include ERB::Util

    use Rack::Session::Cookie, :secret => "change me"
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end

  use OmniAuth::Builder do
    provider :twitter, CONSUMER_KEY, CONSUMER_SECRET
  end

  get '/' do
    erb :index
  end

  get '/auth/twitter/callback' do
    auth = request.env["omniauth.auth"]
    access_token = auth["extra"]["access_token"]
    curr_user = auth["extra"]["raw_info"]

    mongo_user = User.find_or_create_by_user_id(curr_user.id)
    mongo_user.screen_name = curr_user.screen_name
    mongo_user.name = curr_user.name
    mongo_user.profile_image_url = curr_user.profile_image_url
    mongo_user.access_token = access_token.token
    mongo_user.access_secret= access_token.secret
    mongo_user.save

    redirect "/users/#{curr_user.screen_name}/recent"
  end

  get '/users/:screen_name/recent' do
    params[:page] = 1 if params[:page]  == nil || params[:page].to_i < 1
    params[:per_page] = 50 if params[:per_page]  == nil || params[:per_page].to_i < 1

    @page = params[:page]
    @per_page = params[:per_page]
    @user =  User.find_by_screen_name(params[:screen_name])
    return unless @user
    @articles = @user.articles.paginate({
        :order => :updated_at.desc,
        :per_page => @per_page,
        :page => @page,
      })

    @title = @user.screen_name
    @page_type = "recent"
    erb :user_home
  end

  get '/users/:screen_name' do
    user =  User.find_by_screen_name(params[:screen_name])
    return unless user
    @webpages = user.articles.where(:updated_at.gte => 1.days.ago).sort(:updated_at.desc)
    erb :user_home
  end

  get '/users/:screen_name/:year/:mon/:day/' do
    params[:page] = 1 if params[:page]  == nil || params[:page].to_i < 1
    params[:per_page] = 50 if params[:per_page]  == nil || params[:per_page].to_i < 1

    @page = params[:page]
    @per_page = params[:per_page]
    @user =  User.find_by_screen_name(params[:screen_name])
    return unless @user

    begin
      p date_begin = Time.parse("#{params[:year]}-#{params[:mon]}-#{params[:day]} 00:00:00 +0900")
      p date_end   = Time.parse("#{params[:year]}-#{params[:mon]}-#{params[:day]} 23:59:59 +0900")
    rescue => e
      return e.to_s
    end

    @articles = @user.articles.where(:updated_at => {:$gt => date_begin, :$lt => date_end}).paginate({
        :order => :updated_at.desc,
        :per_page => @per_page,
        :page => @page,
      })

    @title = @user.screen_name
    @page_type = "recent"
    erb :user_home
  end

  get '/api/articles/recent' do
    #------------------------------------------------
    # API Parameters
    # screen_name
    # per_page
    # page
    #------------------------------------------------
    page = 1 if params[page] == nil
    per_page = 30 if params[per_page] == nil

    return "please set user" unless params[:screen_name]
    user =  User.find_by_screen_name(params[:screen_name])
    return unless user
    user.articles.paginate({
        :order => :updated_at.desc,
        :per_page => per_page,
        :page => page,
      }).to_json(:include => [:webpage, :statuses, :user])
  end
end

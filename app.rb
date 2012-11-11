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

    use Rack::Session::Cookie, :secret => "change me",
                               :expire_after => 3600 * 24 * 2
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end

  use OmniAuth::Builder do
    provider :twitter, CONSUMER_KEY, CONSUMER_SECRET
  end

  helpers do
    def current_user
      @current_user ||= User.find_by_screen_name(session[:screen_name])
    end

    def login?
      return unless session[:screen_name] or current_user
      return true
    end

    def verify_params(params)
      if params.class != Hash
        params = Hash.new
      end

      params[:page] = 1 if params[:page]  == nil || params[:page].to_i < 1
      params[:per_page] = 50 if params[:per_page]  == nil || params[:per_page].to_i < 1
      params
    end
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

    session[:screen_name] = curr_user.screen_name
    redirect "/"
  end

  get '/' do
    redirect 'home' if login?
    erb :index
  end

  get '/home' do
    redirect '/' unless login?
    params = verify_params(params)

    @articles = current_user.retrieve_articles(params)
    @title = current_user.screen_name
    @page_type = "recent"
    @has_next_page = (@articles.size == params[:per_page])
    @next_page_url = "/home?page=#{params[:page] + 1}" if @has_next_page

    erb :user_home
  end

  get '/users/:screen_name/recent' do
    "move to '/'(require sign-in)"
  end

  get '/users/:screen_name/:year/:mon/:day/' do
    # TODO: どっかにまとめる
    params[:page] = 1 if params[:page]  == nil || params[:page].to_i < 1
    params[:per_page] = 50 if params[:per_page]  == nil || params[:per_page].to_i < 1

    @page = params[:page]
    @per_page = params[:per_page]
    @user =  User.find_by_screen_name(params[:screen_name])
    return unless @user


    # FIXME: ページネイトできてない
    @articles = Articles_in_date.first({
        :user_id => @user.id,
        :year => params[:year].to_i,
        :mon => params[:mon].to_i,
        :day => params[:day].to_i}).articles

    @title = @user.screen_name
    @page_type = "recent"
    erb :user_home
  end

  get '/api/articles/recent' do
    "このAPIはセキュリティ上の問題が報告されているため一時的に利用できません"
  end
end

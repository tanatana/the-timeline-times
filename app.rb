# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)
Bundler.require(:default, :web)
require 'database'
require 'omniauth'
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
    u =  User.find_by_screen_name(params[:screen_name])
    @articles = Article.paginate({
        :order => :updated_at.desc,
        :per_page => 50,
        :page => 1,
      })

    @title = u.screen_name
    @page_type = "recent"
    erb :user_home
  end

  get '/users/:screen_name' do
    u =  User.find_by_screen_name(params[:screen_name])
    @webpages = Webpage.where(:user_id => u.id, :updated_at.gte => 1.days.ago).sort(:updated_at.desc)
    erb :user_home
  end
end

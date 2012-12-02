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

    def paginate_options(params)
      opts = {:page => 1, :per_page => 50}
      opts.each{|k, v| opts[k] = params[k].to_i if params[k] and params[k].to_i > 0}
      opts
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
    redirect '/home' if login?
    erb :index
  end

  before %r{/home|/ajax|/api} do
    redirect '/' unless login?
  end  

  get '/home' do
    opts = paginate_options(params)

    @articles = current_user.retrieve_articles(opts)
    @has_next_page = (@articles.size == opts[:per_page])
    @next_page_url = "/home?page=#{opts[:page] + 1}" if @has_next_page

    erb :home
  end

  get '/home/article/:article_id' do    
    @article = current_user.retrieve_article(params[:article_id])

    erb :article_detail
  end

  get '/home/:year/:mon/:day' do
    opts = paginate_options(params)

    articles_in_date = Articles_in_date.first({
        :user_id => current_user.id,
        :year => params[:year].to_i,
        :mon => params[:mon].to_i,
        :day => params[:day].to_i}).articles.reverse

    @articles = articles_in_date[((opts[:page] - 1) * 50)..((opts[:page] * 50) - 1)]
    @has_next_page = (@articles.size == opts[:per_page])
    @next_page_url = "/home/#{params[:year]}/#{params[:mon]}/#{params[:day]}?page=#{opts[:page] + 1}" if @has_next_page
    erb :home
  end


  get '/ajax/article/:article_id' do
    @article = current_user.retrieve_article(params[:article_id])

    erb :article_detail, :layout => false
  end

  get '/api/article/pickup/:article_id' do
    @article = current_user.retrieve_article(params[:article_id])
    unless @article.pickup
      @article.pickup = true
    else
      @article.pickup = false
    end
      
    @article.save

    return @article.to_json
  end
  
  get '/api/articles/recent' do
    "このAPIはセキュリティ上の問題が報告されているため一時的に利用できません"
  end

  get '/logout' do
    session.delete(:screen_name)
    redirect '/'
  end
end

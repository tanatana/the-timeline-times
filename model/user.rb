class User
  include MongoMapper::Document
  key :user_id, Integer, :required => true
  key :screen_name, String
  key :profile_image_url, String
  key :name, String
  key :access_token, String
  key :access_secret, String
  key :latest_status_id, :default => 1

  many :articles

  timestamps!

  def retrieve_articles(params)
    self.articles.paginate({
        :order => :updated_at.desc,
        :per_page => params[:per_page],
        :page => params[:page],
      })
  end

  def retrieve_article(article_id)
    self.articles.find(article_id)
  end

  def retrieve_pickedup_articles(params)
    self.articles.paginate({
        :pickup => true,
        :order => :updated_at.desc,
        :per_page => params[:per_page],
        :page => params[:page],
      })
  end

end

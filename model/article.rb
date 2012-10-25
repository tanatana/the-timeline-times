class Article
  include MongoMapper::Document
  belongs_to :user

  one :webpage
  many :status
  
  timestamps!
end

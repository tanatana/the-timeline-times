class Articles_in_date
  include MongoMapper::Document

  key :article_ids, Array
  many :articles, :in => :article_ids
  belongs_to :user

  timestamps!
end

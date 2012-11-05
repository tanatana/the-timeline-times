class Article
  include MongoMapper::Document

  key :favorite, :default => false
  key :status_ids, Array
  many :statuses, :in => :status_ids
  belongs_to :user
  belongs_to :webpage

  timestamps!
end

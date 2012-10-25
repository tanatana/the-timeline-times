class Webpage
  include MongoMapper::Document
  belongs_to :article
  
  key :expanded_url, :unique => true
  key :title, String

  many :statuses

  timestamps!
end

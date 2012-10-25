class Webpage
  include MongoMapper::Document
  belongs_to :article
  
  key :expanded_url
  key :title, String

  many :statuses

  timestamps!
end

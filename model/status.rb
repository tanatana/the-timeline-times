class Status
  include MongoMapper::Document
  belongs_to :article
  belongs_to :webpage
  belongs_to :user
  
  timestamps!
end


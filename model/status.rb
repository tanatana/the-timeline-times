class Status
  include MongoMapper::Document
  belongs_to :article
  belongs_to :webpage
  
  userstamps!
  timestamps!
end


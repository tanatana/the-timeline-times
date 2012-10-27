class Webpage
  include MongoMapper::Document
  key :expanded_url
  key :title, String

  key :thumb, String
  
  key :status_ids, Array
  many :statuses, :in => :status_ids
  many :articles

  timestamps!
end

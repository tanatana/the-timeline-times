class Webpage
  include MongoMapper::Document
  belongs_to :article
  # for old version
  belongs_to :user

  key :page_url, String, :required => true
  key :title, String

  many :statuses

  timestamps!
end

class Status
  include MongoMapper::Document
  belongs_to :user
  belongs_to :article
  # for old version
  belongs_to :webpage
  key :status_id, Integer, :required => true, :unique => true
  key :text, String
  key :posted_at, String

  key :active, Boolean, :default => true

  userstamps!
  timestamps!
end


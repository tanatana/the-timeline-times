class Status
  include MongoMapper::Document
  belongs_to :user

  key :status_id, Integer, :required => true, :unique => true
  key :text, String
  key :posted_at, String

  key :active, Boolean, :default => true

  userstamps!
  timestamps!
end


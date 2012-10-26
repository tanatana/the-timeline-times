class User
  include MongoMapper::Document
  key :user_id, Integer, :required => true
  key :screen_name, String
  key :profile_image_url, String
  key :name, String
  key :access_token, String
  key :access_secret, String

  many :articles

  timestamps!
end

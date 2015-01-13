class Api < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :pom    , type: String
  field :pomhash, type: String

  index({ api_key: 1 }, { name: "api_key_index", unique: true, background: true })

  validates :pom    , presence: true
  validates :pomhash, presence: true

end

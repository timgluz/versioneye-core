class ApiCmp < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

# Bucket of components per API Key.

  field :api_key    , type: String
  field :language   , type: String
  field :prod_key   , type: String

  index({ api_key: 1 }, { name: "api_key_index", background: true })
  index({ api_key: 1, language: 1, prod_key: 1 }, { name: "api_lang_prod_index",  background: true, unique: true })

  validates :api_key, presence: true

end

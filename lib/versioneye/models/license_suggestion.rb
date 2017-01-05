class LicenseSuggestion < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # This license belongs to the product with this attributes
  field :language, type: String
  field :prod_key, type: String
  field :version , type: String

  field :name    , type: String # For example MIT
  field :url     , type: String # URL to the license text
  field :comments, type: String

  belongs_to :user, optional: true
  belongs_to :organisation, optional: true

  index({ language: 1, prod_key: 1, version: 1 }, { name: "language_prod_key_version_index", background: true })

  validates_presence_of :language, :message => 'language is mandatory!'
  validates_presence_of :prod_key, :message => 'prod_key is mandatory!'
  validates_presence_of :version , :message => 'version is mandatory!'
  validates_presence_of :name    , :message => 'name is mandatory!'

end

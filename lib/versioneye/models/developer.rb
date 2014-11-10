class Developer < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # This developer belongs to the product with this attributes
  field :language        , type: String
  field :prod_key        , type: String
  field :version         , type: String

  field :developer       , type: String # This is the username of the developer! Legacy. The name is taken from maven. The very first implementation.
  field :name            , type: String # This is the real name of the developer!
  field :email           , type: String
  field :homepage        , type: String
  field :organization    , type: String
  field :organization_url, type: String
  field :role            , type: String
  field :timezone        , type: String

  index({ language: 1, prod_key: 1, version: 1, name: 1 }, { name: "language_prod_key_version_name_index", background: true })
  index({ language: 1, prod_key: 1, version: 1 },          { name: "language_prod_key_version_index",      background: true })
  index({ language: 1, prod_key: 1 },                      { name: "language_prod_key_index",              background: true })

  def to_s
    "#{name} - #{email}"
  end

  def self.find_by language, prod_key, version, name = nil
    if name.nil?
      return Developer.where( language: language, prod_key: prod_key, version: version, name: name )
    else
      return Developer.where( language: language, prod_key: prod_key, version: version )
    end
  end

end

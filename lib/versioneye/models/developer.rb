class Developer < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # This developer belongs to the product with this attributes
  field :language        , type: String
  field :prod_key        , type: String
  field :version         , type: String

  # combination of language and prod_key
  field :lang_key        , type: String

  field :developer       , type: String # This is the username of the developer! Legacy. The name is taken from maven. The very first implementation.
  field :name            , type: String # This is the real name of the developer!
  field :email           , type: String
  field :homepage        , type: String
  field :organization    , type: String
  field :organization_url, type: String
  field :role            , type: String
  field :timezone        , type: String
  field :contributor     , type: Boolean, default: false

  field :to_author       , type: Boolean, default: false


  index({ language: 1, prod_key: 1, version: 1, name: 1 }, { name: "language_prod_key_version_name_index", background: true, unique: true, drop_dups: true })
  index({ language: 1, prod_key: 1, version: 1 },          { name: "language_prod_key_version_index",      background: true })
  index({ language: 1, prod_key: 1 },                      { name: "language_prod_key_index",              background: true })
  index({ name: 1 }, { name: "name_index", background: true })


  before_save :update_lang_key


  def to_s
    "#{name} - #{email}"
  end


  def dev_identifier
    return self.name if !self.name.to_s.empty?
    return self.developer
  end


  def to_param
    return Author.encode_name(self.name)      if !self.name.to_s.empty?
    return Author.encode_name(self.developer) if !self.developer.to_s.empty?
    return ""
  end


  def product
    Product.fetch_product language, prod_key
  end


  def update_lang_key
    self.lang_key = "#{language}:::#{prod_key}".downcase
  end


  def self.find_by language, prod_key, version, name = nil
    if name.nil?
      return Developer.where( language: language, prod_key: prod_key, version: version )
    else
      return Developer.where( language: language, prod_key: prod_key, version: version, name: name )
    end
  end


end

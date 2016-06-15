class Author < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name_id         , type: String # name without white spaces and downcased
  field :name            , type: String # This is the real name of the developer!
  field :email           , type: String
  field :homepage        , type: String
  field :organization    , type: String
  field :organization_url, type: String
  field :role            , type: String
  field :timezone        , type: String
  field :contributor     , type: Boolean, default: false

  field :emails        , type: Array, default: []
  field :emails_count  , type: Integer, default: 0

  field :languages        , type: Array, default: []  # Uniq. language codes
  field :languages_count  , type: Integer, default: 0

  field :product_ids     , type: Array, default: []
  field :products        , type: Array  # Array of <LANGUAGE>::<PROD_KEY>
  field :products_count  , type: Integer, default: 0

  validates_presence_of :name, :message => 'is mandatory!'

  validates_uniqueness_of :name_id, :message => 'exist already.'

  index({ name_id: 1 }, { name: "nameid_index", background: true, unique: true, drop_dups: true })
  index({ products_count: 1 }, { name: "products_count_index", background: true })


  def to_s
    "#{name_id} - #{email}"
  end


  def to_param
    return name_id if !name_id.to_s.empty?
    Author.encode_name(name) if !name.to_s.empty?
  end


  def update_name_id
    self.name_id = Author.encode_name( self.name )
  end


  def self.encode_name name
    name.gsub(" ", "_").gsub("ß", "ss")
      .gsub("/", ":")
      .gsub("ü", "ue").gsub("Ü", "Ue")
      .gsub("ä", "ae").gsub("Ä", "Ae")
      .gsub("ö", "oe").gsub("Ö", "Oe").downcase
  end


  def add_product id, language, prod_key
    key = "#{language}::#{prod_key}".downcase
    self.products = [] if products.nil?
    self.products.push( key ) if !products.include?(key)
    self.products_count = self.products.count
    self.product_ids.push( id ) if id && !product_ids.include?( id )

    self.languages.push( language ) if !self.languages.include?( language )
    self.languages_count = self.languages.count

    self.save
  end


  def update_from developer
    self.name             = developer.name             if !developer.name.to_s.empty?
    self.email            = developer.email            if !developer.email.to_s.empty?
    self.homepage         = developer.homepage         if !developer.homepage.to_s.empty?
    self.organization     = developer.organization     if !developer.organization.to_s.empty?
    self.organization_url = developer.organization_url if !developer.organization_url.to_s.empty?
    self.role             = developer.role             if !developer.role.to_s.empty?
    self.timezone         = developer.timezone         if !developer.timezone.to_s.empty?
    self.contributor      = developer.contributor      if !developer.contributor.to_s.empty?
    if !self.emails.include?( developer.email )
      self.emails.push developer.email
      self.emails_count = self.emails.count
    end
    self.save
  end


end

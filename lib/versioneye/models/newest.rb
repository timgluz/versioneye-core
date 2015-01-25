class Newest < Versioneye::Model

  # Every time a crawler is finding a new product or a new version of a product
  # it has to create a 'newest' entry.

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name      , type: String
  field :version   , type: String
  field :language  , type: String
  field :prod_key  , type: String
  field :prod_type , type: String
  field :product_id, type: String
  field :processed , type: Boolean, default: false

  scope :by_language, ->(lang){where(language: lang)}

  index({language: 1, prod_key: 1, version: 1}, { name: "lang_prod_vers_index",   background: true, unique: true })
  index({updated_at: -1},                       { name: "updated_at_index",       background: true})
  index({updated_at: -1, language: -1},         { name: "updated_language_index", background: true})
  index({created_at: -1, language: -1},         { name: "created_language_index", background: true})
  index({created_at: -1},                       { name: "created_at_index",       background: true})
  index({language:   -1},                       { name: "language_index",         background: true})


  def to_s
    "#{language} : #{prod_key} : #{version}"
  end

  def product
    if !self.product_id.to_s.empty?
      product = Product.find(self.product_id) 
      return product if product
    end 
    return Product.fetch_product self.language, self.prod_key
  end

  def self.fetch_newest language, prod_key, version
    Newest.where(:language => language, :prod_key => prod_key, :version => version).shift
  end

  def self.get_newest( count )
    Newest.all().desc( :created_at ).limit( count )
  end

  def self.since_to(dt_since, dt_to)
    self.where(:created_at.gte => dt_since, :created_at.lt => dt_to).desc(:created_at)
  end

  def self.balanced_newest(count)
    newest = []
    Product::A_LANGS_SUPPORTED.each do |lang|
      newest.concat Newest.where(language: lang).desc(:created_at).limit(count)
    end
    newest.shuffle.first(count)
  end

  def self.balanced_novel(count)
    newest = []
    Product::A_LANGS_SUPPORTED.each do |lang|
      newest.concat Newest.where(language: lang, novel: true).desc(:created_at).limit(count)
    end
    newest.shuffle.first(count)
  end

  def language_esc
    return 'nodejs' if language.eql?(Product::A_LANGUAGE_NODEJS)
    language.downcase
  end

end

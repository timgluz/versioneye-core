class Product < Versioneye::Model

  require 'versioneye/models/helpers/product_constants'
  include VersionEye::ProductConstants

  require 'versioneye/models/helpers/product_es_mapping'
  include VersionEye::ProductEsMapping

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name         , type: String
  field :name_downcase, type: String
  field :prod_key     , type: String # Unique identifier inside a language
  field :prod_type    , type: String # Identifies the package manager
  field :language     , type: String
  field :version      , type: String, default: '0.0.0+NA' # latest stable version

  field :group_id   , type: String # Maven specific
  field :artifact_id, type: String # Maven specific
  field :parent_id  , type: String # Maven specific

  field :description       , type: String
  field :description_manual, type: String

  field :downloads         , type: Integer, default: 0
  field :followers         , type: Integer, default: 0
  field :used_by_count     , type: Integer, default: 0 # Number of references, projects using this one.
  field :dep_count         , type: Integer, default: 0 # Number of direct dependencies.

  field :twitter_name, type: String

  field :reindex, type: Boolean, default: true # Trigger to reindex in ElasticSearch

  embeds_many :versions     # unsorted versions
  embeds_many :repositories

  has_and_belongs_to_many :users

  validates_presence_of :language , :message => 'language  is mandatory!'
  validates_presence_of :prod_type, :message => 'prod_type is mandatory!'
  validates_presence_of :prod_key , :message => 'prod_key  is mandatory!'
  validates_presence_of :name     , :message => 'name      is mandatory!'

  # For indexing use task: rake db:mongoid:create_indexes
  index({ prod_key: 1, language: 1, version: 1 }, { name: "prod_key_language_version_index", unique: true, background: true })
  index({ prod_key: 1, language: 1 },    { name: "prod_key_language_index", unique: true, background: true })
  index({ name: 1 },                     { name: "name_index", background: true })
  index({ name_downcase: 1 },            { name: "name_downcase_index", background: true })
  index({ group_id: 1, artifact_id: 1 }, { name: "group_id_artifact_id_index", background: true })
  index({ prod_type: 1, name: 1 },       { name: "prod_type_name_index", background: true })
  index({ used_by_count: -1 },           { name: "used_by_count_index", background: true })
  index({ followers:  -1},               { name: "followers_index", background: true})
  index({ created_at: -1},               { name: "created_at_index", background: true})
  index({ updated_at: -1},               { name: "updated_at_index", background: true})
  index({ updated_at: -1, language: -1}, { name: "updated_language_index", background: true})

  attr_accessor :average_release_time
  attr_accessor :released_days_ago, :released_ago_in_words, :released_ago_text
  attr_accessor :in_my_products, :dependencies_cache

  scope :by_language, ->(lang){where(language: lang)}


  def show_dependency_badge?
    A_LANGS_DEP_BADGE.include?(self.language)
  end

  def save(*arg)
    self.name_downcase = self.name.downcase if self.name
    super
  end

  def to_s
    "<Product #{language} / #{prod_key} (#{version}) >"
  end

  def to_param
    Product.encode_prod_key self.prod_key
  end

  ######## SEARCH METHODS ####################

  def self.find_by_id id
    self.find id
  rescue => e
    log.error e.message
    nil
  end

  def self.fetch_product lang, key
    return nil if lang.to_s.strip.empty? || key.to_s.strip.empty?
    return Product.find_by_key( key ) if lang.eql? 'package'

    product = Product.find_by_lang_key( lang, key.downcase )
    product = Product.find_by_lang_key( lang, key ) if product.nil?
    product
  end

  def self.fetch_bower name
    Product.where(prod_type: Project::A_TYPE_BOWER, name: name).first
  end

  # legacy, still used by fall back search and API v1.0
  def self.find_by_key searched_key
    Product.where(prod_key: searched_key).first
  end

  def self.find_by_lang_key language, searched_key
    Product.where(language: language, prod_key: searched_key).shift
  end

  def self.find_by_group_and_artifact group, artifact
    return nil if group.to_s.strip.empty? || artifact.to_s.strip.empty?
    Product.where( group_id: group, artifact_id: artifact ).shift
  end

  def self.by_prod_keys language, prod_keys
    if language.to_s.strip.empty? || prod_keys.nil? || prod_keys.empty? || !prod_keys.is_a?(Array)
      return Mongoid::Criteria.new(Product).where(:prod_key => "-1-1")
    end
    Product.where(:language => language, :prod_key.in => prod_keys)
  end

  ######## START VERSIONS ###################

  def sorted_versions
    Naturalsorter::Sorter.sort_version_by_method( versions, "version", false )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    versions
  end

  def version_by_number searched_version
    versions.each do |version|
      return version if version.to_s.eql?( searched_version )
    end
    nil
  rescue => e
    log.error e
    nil
  end

  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  def add_version(version_string, hash = {})
    unless version_by_number(version_string)
      version_hash = {:version => version_string}
      version_hash.merge(hash) if !hash.nil? and !hash.empty?
      version = Version.new(version_hash)
      versions.push( version )
    end
  end

  def check_nil_version
    if versions && !versions.empty? && (version.nil? || version.eql?('0.0.0+NA'))
      self.version = sorted_versions.first
      self.save
    end
  end

  ######## ENCODE / DECODE ###################

  def self.encode_prod_key prod_key
    return "0" if prod_key.to_s.strip.empty?
    prod_key.to_s.gsub('/', ':')
  end

  def self.decode_prod_key prod_key
    return nil if prod_key.to_s.strip.empty?
    prod_key.to_s.gsub(':', '/')
  end

  def self.encode_language language
    return nil if language.to_s.strip.empty?
    language.to_s.gsub("\.", "").downcase
  end

  def self.decode_language language
    return nil if language.to_s.strip.empty?
    return A_LANGUAGE_NODEJS       if language.match(/\Anode/i)
    return A_LANGUAGE_CSS          if language.match(/\ACSS/i)
    return A_LANGUAGE_PHP          if language.match(/\Aphp/i)
    return A_LANGUAGE_OBJECTIVEC   if language.match(/\AObjective-C/i)
    return A_LANGUAGE_JAVASCRIPT   if language.match(/\AJavaScript/i)
    return A_LANGUAGE_COFFEESCRIPT if language.match(/\ACoffeeScript/i)
    return A_LANGUAGE_ACTIONSCRIPT if language.match(/\AActionScript/i)
    return A_LANGUAGE_TYPESCRIPT   if language.match(/\ATypeScript/i)
    return A_LANGUAGE_LIVESCRIPT   if language.match(/\ALiveScript/i)
    return language.capitalize
  end

  def update_in_my_products array_of_product_ids
    self.in_my_products = array_of_product_ids.include?(_id.to_s)
  end

  ########## ELSE #############

  def description_summary
    if description && description_manual
      "#{description} \n \n #{description_manual}"
    elsif description && !description_manual
      return description
    elsif !description && description_manual
      return description_manual
    else
      ''
    end
  end

  def short_summary
    desc = description
    desc = description_manual if description_manual.to_s.length > description.to_s.length
    return get_summary( desc , 125)
  end

  def name_and_version
    "#{name} : #{version}"
  end

  def name_version limit
    nameversion = "#{name} (#{version})"
    if nameversion.length > limit
      "#{nameversion[0, limit]}.."
    else
      nameversion
    end
  end

  def language_esc lang = nil
    lang = self.language if lang.nil?
    Product.encode_language lang
  end

  def license_info
    licenses = self.licenses false
    return 'unknown' if licenses.nil? || licenses.empty?
    licenses.map{|a| a.name}.join(', ')
  end

  def comments
    Versioncomment.find_by_prod_key_and_version(self.language, self.prod_key, self.version)
  end

  # An artifact (product + version) can have multiple licenses
  # at the same time. That's not a bug!
  def licenses ignore_version = false
    substitute_names = []
    licenses = []
    lics = License.for_product self, ignore_version
    lics.each do |license|
      if !substitute_names.include?( license.name_substitute )
        substitute_names << license.name_substitute
        licenses << license
      end
    end
    licenses
  end

  def developers
    Developer.find_by self.language, self.prod_key, version
  end

  def dependencies scope = nil
    dependencies_cache ||= {}
    scope = Dependency.main_scope(self.language) unless scope
    if dependencies_cache[scope].nil?
      dependencies_cache[scope] = Dependency.find_by_lang_key_version_scope( language, prod_key, version, scope )
    end
    dependencies_cache[scope]
  end

  def all_dependencies
    Dependency.find_by_lang_key_and_version( language, prod_key, version)
  end

  def http_links
    links = Versionlink.where(language: language, prod_key: self.prod_key, version_id: nil).asc(:name)
    get_http_links links
  end

  def http_version_links
    links = Versionlink.where(language: language, prod_key: self.prod_key, version_id: self.version ).asc(:name)
    get_http_links links
  end

  def archives
    downloads = Versionarchive.archives( self.language, self.prod_key, version.to_s )
  end

  def self.unique_languages_for_product_ids(product_ids)
    Product.where(:_id.in => product_ids).distinct(:language)
  end

  def to_url_path
    "/#{language_esc}/#{to_param}"
  end

  def version_to_url_param
    Version.encode_version version
  end

  def main_scope
    Dependency.main_scope self.language
  end

  private

    def get_summary text, size
      return '' if text.nil?
      return "#{text[0..size]}..." if text.size > size
      text[0..size]
    end

    def get_http_links links
      result = []
      return result if links.nil? || links.empty?

      links.each do |link|
        next if link.nil?
        next if link.link.to_s.empty?
        next if link.link.match(/\Ahttp*/) == nil
        result << link
      end
      result
    end

end

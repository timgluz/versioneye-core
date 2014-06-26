class Versionlink < Versioneye::Model

  # A versionlink describes an URL which belongs to an software package.
  # Some versionlinks belong to a specific version of a software package.
  # For example URLs to Maven artifact directories. E.g.:
  # http://gradle.artifactoryonline.com/gradle/libs/org/hibernate/hibernate-core/3.3.0.CR1/
  #
  # Other URLs are project specific and belong to all versions of the software package. For
  # example a URL to the project homepage.
  #
  # If version_id is nil this link belongs to all versions of the package.
  # It's a so called project link.

  include Mongoid::Document
  include Mongoid::Timestamps

  # Belongs to the product with this attributes
  field :language  , type: String
  field :prod_key  , type: String
  field :version_id, type: String # version string. For example 1.0.1. This value can be nil. TODO rename to version.

  field :link      , type: String # URL:   for example https://github.com/500px/500px-iOS-api
  field :name      , type: String # Label: for example "500px-iOS-api"

  # true  => This link was manually added by a community member
  # false => This link was crawled
  field :manual    , type: Boolean, :default => false

  index({ language: 1, prod_key: 1, version_id: 1, link: 1 }, { name: "lang_prod_vers_link_index", background: true, unique: true })
  index({ language: 1, prod_key: 1, version_id: 1 }, { name: "lang_prod_vers_index", background: true })
  index({ language: 1, prod_key: 1                }, { name: "lang_prod_index", background: true })


  def as_json parameter
    {
      :name => self.name,
      :link => self.link
    }
  end


  def product
    product = Product.find_by_lang_key( self.language, self.prod_key )
    return nil if product.nil?

    product.version = self.version_id
    product
  end


  def self.create_project_link( language, prod_key, url, name )
    link = Versionlink.where( language: language, prod_key: prod_key, link: url, :version_id => nil ).shift
    return link if link

    versionlink = Versionlink.new({:language => language, :prod_key => prod_key, :link => url, :name => name})
    versionlink.save
    versionlink
  end


  def self.remove_project_link( language, prod_key, link, manual )
    return nil if link.to_s.strip.empty?
    Versionlink.where( language: language, prod_key: prod_key, link: link, :version_id => nil, :manual => manual ).delete_all
  end


  def self.find_version_link(language, prod_key, version_id, link)
    Versionlink.where( language: language, prod_key: prod_key, version_id: version_id, link: link )
  end


  def self.create_versionlink language, prod_key, version_number, link, name
    return nil if link.to_s.empty?

    if link.match(/\Ahttp.*/).nil? && link.match(/\Agit.*/).nil?
      link = "http://#{link}"
    end

    versionlinks = Versionlink.find_version_link(language, prod_key, version_number, link)
    if versionlinks && !versionlinks.empty?
      log.info "-- link exist already : #{prod_key} - #{version_number} - #{link} - #{name}"
      return nil
    end

    versionlink = Versionlink.new({:name => name, :link => link,
      :language => language, :prod_key => prod_key,
      :version_id => version_number })
    versionlink.save
  end


  def get_link
    return "http://#{self.link}" if self.link.match(/\Awww.*/) != nil
    self.link
  end


end

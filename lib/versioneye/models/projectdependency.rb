class Projectdependency < Versioneye::Model

  require 'naturalsorter'

  # This Model describes the relationship between a project and a package
  # This Model describes 1 dependency of a project

  include Mongoid::Document
  include Mongoid::Timestamps

  # This project dependency refers to the product with the given language and prod_key
  field :language   , type: String
  field :prod_key   , type: String
  field :ext_link   , type: String # Link to external package. For example zip file on GitHub / Google Code.

  field :name       , type: String
  field :group_id   , type: String # Maven specific
  field :artifact_id, type: String # Maven specific

  field :version_current  , type: String  # the newest version from the database
  field :version_requested, type: String  # requested version from the project file -> locked version
  field :version_label    , type: String  # the version number from the projectfile (Gemfile, package.json)
  field :comperator       , type: String, :default => '='
  field :scope            , type: String, :default => Dependency::A_SCOPE_COMPILE
  field :release          , type: Boolean
  field :stability        , type: String, :default => VersionTagRecognizer::A_STABILITY_STABLE

  field :outdated           , type: Boolean
  field :outdated_updated_at, type: DateTime, :default => DateTime.now
  field :muted              , type: Boolean , :default => false

  belongs_to :project


  def to_s
    "<Projectdependency: #{project} depends on #{name} (#{version_label}) current: #{version_current} >"
  end

  def product
    Product.fetch_product( self.language, self.prod_key.to_s.downcase )
  end

  def find_or_init_product
    product = Product.fetch_product( language, prod_key)
    if product.nil? && ( !group_id.to_s.empty? && !artifact_id.to_s.empty? )
      product = Product.find_by_group_and_artifact self.group_id, self.artifact_id
    end
    unless product
      product = init_product
    end
    product
  end

  def unknown?
    prod_key.nil? && ext_link.nil?
  end

  def known?
    !self.unknown?
  end

  private

    def init_product
      product             = Product.new
      product.name        = self.name
      product.group_id    = self.group_id
      product.artifact_id = self.artifact_id
      product
    end

end

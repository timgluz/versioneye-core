class Dependency < Versioneye::Model

  require 'versioneye/models/project'
  require 'versioneye/models/product'

  # This Model describes the relationship between 2 products/packages
  # This Model describes 1 dependency of a package to another package

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SCOPE_RUNTIME     = 'runtime'     # RubyGems
  A_SCOPE_REQUIRE     = 'require'     # PHP Composer, Bower
  A_SCOPE_PROVIDED    = 'provided'    # Java Maven
  A_SCOPE_TEST        = 'test'        # Java Maven
  A_SCOPE_COMPILE     = 'compile'     # NPM, Maven and many more!
  A_SCOPE_DEVELOPMENT = 'development' # NPM, Bower
  A_SCOPE_BUNDLED     = 'bundled'     # NPM
  A_SCOPE_OPTIONAL    = 'optional'    # NPM

  # Podspecs of CocoaPods doesn't have scopes/targets
  # But Podfiles can have targets

  # This attributes describe to which product
  # this dependency belongs to. Parent!
  field :prod_type   , type: String,  :default => Project::A_TYPE_RUBYGEMS
  field :language    , type: String,  :default => Product::A_LANGUAGE_RUBY
  field :prod_key    , type: String   # This dependency belongs to this prod_key
  field :prod_version, type: String   # This dependency belongs to this version of prod_key

  # This attributes describe the dependency itself!
  field :dep_prod_key, type: String   # prod_key of the dependency (Foreign Key)
  field :name        , type: String
  field :group_id    , type: String   # Maven specific
  field :artifact_id , type: String   # Maven specific
  field :version     , type: String   # version of the dependency. This is the unfiltered version string. It is not parsed yet.
  field :scope       , type: String
  field :targetFramework, type: String # .NET & Nuget specific

  # known or unknown dependency.
  # If there is no product for dep_prod_key in our db then it's unknown
  field :known       , type: Boolean

  # The current/newest version of the product, which this dep is referencing
  field :current_version, type: String
  # The parsed version, without operator
  field :parsed_version , type: String
  field :outdated, type: Boolean

  index({ language: 1, prod_key: 1, prod_version: 1, dep_prod_key: 1, version: 1, scope: 1 }, { name: "parent_fk_index", background: true, unique: true, drop_dups: true})
  index({ language: 1, prod_key: 1, prod_version: 1 }, { name: "prod_key_lang_ver_index", background: true })
  index({ language: 1, dep_prod_key: 1 }, { name: "language_dep_prod_key_index" , background: true })
  index({ group_id: 1, artifact_id: 1 }, { name: "groupid_artifactid_index" , background: true })


  def self.remove_dependencies language, prod_key, version
    Dependency.where( language: language, prod_key: prod_key, prod_version: version ).delete_all
  end

  def self.find_by_lang_key_and_version( language, prod_key, version)
    langs = language_array(language)
    Dependency.where( :language.in => langs, prod_key: prod_key, prod_version: version )
  end

  def self.find_by_lang_key_version_scope(language, prod_key, version, scope)
    langs = language_array(language)
    if scope
      return Dependency.where( :language.in => langs, prod_key: prod_key, prod_version: version, scope: scope )
    else
      return Dependency.where( :language.in => langs, prod_key: prod_key, prod_version: version )
    end
  end

  def self.find_by(language, prod_key, prod_version, dep_name, dep_version, dep_prod_key)
    dependencies = Dependency.where(language: language, prod_key: prod_key, prod_version: prod_version, name: dep_name, version: dep_version, dep_prod_key: dep_prod_key)
    return nil if dependencies.nil? || dependencies.empty?
    dependencies[0]
  end

  def product
    return maven_product( group_id, artifact_id ) if group_id && artifact_id
    return bower_product( dep_prod_key ) if prod_type && prod_type.eql?(Project::A_TYPE_BOWER)
    Product.fetch_product( language, dep_prod_key )
  end

  # In the world of Maven (Java) every package is identified by a group_id and artifact_id.
  def maven_product( group_id, artifact_id )
    Product.find_by_group_and_artifact( group_id, artifact_id, language )
  end

  # prod_key for bower packages are assembled by 'owner/bower_name'. We did it that way
  # because on bower the names are case sensitive. To avoid case sensitive URLs we descided
  # to take the owner into the prod_key.
  # Unfortunately the dependencies in the bower.json only contains the bower name, without the owner.
  # That's why we fetch dependencies for bower through prod_type and name. This combination is unique.
  def bower_product( dep_prod_key )
    Product.where(:prod_type => Project::A_TYPE_BOWER, :prod_key => dep_prod_key).shift
  end

  def parent_product
    Product.fetch_product( language, prod_key )
  end

  def language_escaped
    Product.encode_language( language )
  end

  def update_known
    self.known = self.product.nil?() ? false : true
    self.save()
  end

  def update_known_if_nil
    self.update_known() if self.known.nil?
  end

  def self.main_scope( language, prod_type = nil )
    if prod_type.to_s.eql?( Project::A_TYPE_BOWER )
      return A_SCOPE_REQUIRE
    end

    if language.eql?( Product::A_LANGUAGE_RUBY )
      return A_SCOPE_RUNTIME
    elsif language.eql?( Product::A_LANGUAGE_JAVA ) || language.eql?( Product::A_LANGUAGE_CLOJURE ) || language.eql?( Product::A_LANGUAGE_BIICODE )
      return A_SCOPE_COMPILE
    elsif language.eql?( Product::A_LANGUAGE_NODEJS)
      return A_SCOPE_COMPILE
    elsif language.eql?( Product::A_LANGUAGE_PHP ) || language.eql?( Product::A_LANGUAGE_JAVASCRIPT )
      return A_SCOPE_REQUIRE
    end
  end

  def dep_prod_key_for_url
    Product.encode_prod_key dep_prod_key
  end

  def version_for_url
    Version.encode_version( parsed_version )
  rescue => e
    log.error e.message
    return self.version
  end

  def to_s
    "Dependency - #{language}:#{prod_key}:#{prod_version} depends on #{dep_prod_key}:#{version} scope: #{scope} - name: #{name}"
  end

  def set_prod_type_if_nil
    self.prod_type = Project::A_TYPE_RUBYGEMS  if self.language.eql?(Product::A_LANGUAGE_RUBY)
    self.prod_type = Project::A_TYPE_COMPOSER  if self.language.eql?(Product::A_LANGUAGE_PHP)
    self.prod_type = Project::A_TYPE_PIP       if self.language.eql?(Product::A_LANGUAGE_PYTHON)
    self.prod_type = Project::A_TYPE_NPM       if self.language.eql?(Product::A_LANGUAGE_NODEJS)
    self.prod_type = Project::A_TYPE_MAVEN2    if self.language.eql?(Product::A_LANGUAGE_JAVA)
    self.prod_type = Project::A_TYPE_LEIN      if self.language.eql?(Product::A_LANGUAGE_CLOJURE)
    self.prod_type = Project::A_TYPE_BOWER     if self.language.eql?(Product::A_LANGUAGE_JAVASCRIPT)
    self.prod_type = Project::A_TYPE_COCOAPODS if self.language.eql?(Product::A_LANGUAGE_OBJECTIVEC)
    self.prod_type = Project::A_TYPE_BIICODE   if self.language.eql?(Product::A_LANGUAGE_BIICODE)
    self.prod_type = Project::A_TYPE_CHEF      if self.language.eql?(Product::A_LANGUAGE_CHEF)
    self
  end

  private

    def self.language_array language
      langs = [language]
      if language.eql?(Product::A_LANGUAGE_CLOJURE || language.eql?(Product::A_LANGUAGE_JAVA))
        langs = [Product::A_LANGUAGE_CLOJURE, Product::A_LANGUAGE_JAVA]
      end
      langs
    end


end

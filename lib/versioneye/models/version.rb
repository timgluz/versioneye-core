class Version < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid            , type: String
  field :version        , type: String
  field :downloads      , type: Integer
  field :pom            , type: String # maven specific
  field :tag            , type: String # biicode specific - git tag string
  field :tags           , type: Array, default: [] # distribution tags for NPM(latest, next, etc)
  field :status         , type: String # Userd in biitcode & Nuget - [STABLE, DEV, PRERELEASE]

  field :release_id     , type: String # CPAN specific, it's unique id to get version release details
  field :modules        , type: Array  # Cpan specific, it includes all the version specific modules
  field :released_at    , type: DateTime, default: DateTime.now
  field :released_string, type: String
  field :sv_ids         , type: Array, default: []  # SecurityVulnerability IDs
  field :tested_runtimes, type: String
  field :sha1           , type: String
  field :sha256         , type: String
  field :sha512         , type: String
  field :md5            , type: String
  field :commit_sha     , type: String
  field :prefer_global  , type: Boolean, default: false

  embedded_in :product

  attr_accessor :semver_2

  def to_s
    version.to_s
  end

  def eql?( obj )
    self.to_s.eql?( obj.to_s )
  end

  def as_json(parameter=nil)
    {
      :version    => self.version,
      :uid        => self.get_decimal_uid,
      :created_at => self.created_at.strftime('%Y.%m.%d %I:%M %p'),
      :updated_at => self.updated_at.strftime('%Y.%m.%d %I:%M %p')
    }
  end

  def self.encode_version(version)
    return nil if version.nil?
    version.gsub('/', ':')
  end

  def self.decode_version(version)
    return nil if version.nil?
    version.gsub(':', '/')
  end

  def to_param
    val = Version.encode_version(self.version)
    "#{val}".strip
  end

  def released_or_detected
    return released_at if !released_at.nil? && !released_at.to_s.empty?
    created_at
  end

  def security_vulnerabilities
    return nil if sv_ids.to_a.empty?
    SecurityVulnerability.where(:_id.in => sv_ids)
  end

  def licenses
    License.where(:language => product.language, :prod_key => product.prod_key, :version => self.version)
  end

  def add_license( name )
    License.find_or_create_by( :language => product.language, :prod_key => product.prod_key, :version => self.version, :name => name )
  end

  def to_artefact!
    if !self.sha1.to_s.empty? && Artefact.where(:sha_value => self.sha1).count == 0
      create_artefact(self.sha1, "sha1")
    end
    if !self.sha256.to_s.empty? && Artefact.where(:sha_value => self.sha256).count == 0
      create_artefact(self.sha256, "sha256")
    end
    if !self.sha512.to_s.empty? && Artefact.where(:sha_value => self.sha512).count == 0
      create_artefact(self.sha512, "sha512")
    end
  end

  def create_artefact(sha_value, sha_method)
    artefact = Artefact.new({:language => product.language,
                  :prod_key => product.prod_key,
                  :version => self.version,
                  :group_id => product.group_id,
                  :artifact_id => product.artifact_id,
                  :prod_type => product.prod_type,
                  :sha_value => sha_value,
                  :sha_method => sha_method})
    artefact.save
  rescue => e
    log.error e.message
    false
  end

end

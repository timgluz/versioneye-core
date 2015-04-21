class Version < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid            , type: String
  field :version        , type: String
  field :downloads      , type: Integer
  field :pom            , type: String # maven specific 
  field :tag            , type: String # biicode specific - git tag string 
  field :status         , type: String # biicode specific - [STABLE, DEV]
  field :released_at    , type: DateTime
  field :released_string, type: String

  embedded_in :product

  attr_accessor :semver_2

  def to_s
    version.to_s
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
    return released_at if released_at
    created_at
  end

end

class LicenseElement < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/traits/license_normalizer'
  include VersionEye::LicenseNormalizer

  field :name, type: String

  validates_presence_of :name, :message => 'is mandatory!'

  embedded_in :license_whitelist

  def to_s
    name
  end

  def to_param
    name
  end

end

class LicenseElement < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/traits/license_trait'
  include VersionEye::LicenseTrait

  field :name, type: String

  embedded_in :license_whitelist

  def to_s
    name
  end

  def to_param
    name
  end

end

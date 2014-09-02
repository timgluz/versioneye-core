class LicenseWhitelist < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/traits/license_trait'
  include VersionEye::LicenseTrait

  field :name, type: String

  belongs_to :user

  def to_s
    name
  end

  def update_from params
    self.name = params[:name]
  end

end

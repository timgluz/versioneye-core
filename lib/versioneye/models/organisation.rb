class Organisation < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  has_many :projects
  has_many :teams
  # has_many license_whitelists
  # has_many component_whitelists

end

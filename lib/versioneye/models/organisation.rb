class Organisation < Versioneye::Model

  # Non Profit Domains

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name       , type: String
  field :description, type: String

  validates_presence_of :name, :message => 'is mandatory!'
  validates_uniqueness_of :name, :message => 'exist already.'

end

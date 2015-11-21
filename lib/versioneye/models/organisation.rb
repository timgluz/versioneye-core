class Organisation < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :company, type: String
  field :location, type: String
  field :email, type: String
  field :website, type: String

  has_many :projects
  has_many :teams
  # has_many license_whitelists
  # has_many component_whitelists

  validates_presence_of :name, :message => 'is mandatory!'
  validates_uniqueness_of :name, :message => 'exist already.'
  index({ username: 1 }, { name: "username_index", background: true, unique: true })

  def to_s
    name
  end

  def to_param
    name
  end

end

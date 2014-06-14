class NpDomain < Versioneye::Model

  # Non Profit Domains

  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain       , type: String , default: '@etna-alternance.net'
  field :free_projects, type: Integer, default: 50

  validates_presence_of :domain       , :message => 'is mandatory!'
  validates_presence_of :free_projects, :message => 'is mandatory!'

  validates_uniqueness_of :domain, :message => 'exist already.'

end

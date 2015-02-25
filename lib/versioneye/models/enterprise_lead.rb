class EnterpriseLead < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :scm           , type: String, default: 'GitHub Enterprise'
  field :repository    , type: String, default: 'Nexus'
  field :ci            , type: String, default: 'Jenkins'
  field :virtualization, type: String, default: 'VMWare'
  field :name          , type: String
  field :email         , type: String , default: 'notify@versioneye.com'
  field :note          , type: String

  validates_presence_of :scm,            :message => 'is mandatory!'
  validates_presence_of :repository,     :message => 'is mandatory!'
  validates_presence_of :ci,             :message => 'is mandatory!'
  validates_presence_of :virtualization, :message => 'is mandatory!'
  validates_presence_of :name,           :message => 'is mandatory!'
  validates_presence_of :email,          :message => 'is mandatory!'
  validates_presence_of :note,           :message => 'is mandatory!'

end

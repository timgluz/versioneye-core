class EnterpriseLead < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :scm           , type: String, default: 'github'
  field :repository    , type: String, default: 'nexus'
  field :ci            , type: String, default: 'jenkins'
  field :virtualization, type: String, default: 'vmware'
  field :package_managers, type: String
  field :name          , type: String
  field :email         , type: String
  field :note          , type: String


  validates_presence_of :scm,            :message => 'is mandatory'
  validates_presence_of :repository,     :message => 'is mandatory'
  validates_presence_of :ci,             :message => 'is mandatory'
  validates_presence_of :virtualization, :message => 'is mandatory'
  validates_presence_of :name,           :message => 'is mandatory'
  validates_presence_of :email,          :message => 'is mandatory'

end

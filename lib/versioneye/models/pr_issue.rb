class Pr_Issue < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SCM_GITHUB     = 'github'

  A_STATUS_SUCCESS = 'SUCCESS'
  A_STATUS_ERROR   = 'ERROR'

  A_ISSUE_SECURITY = 'SUCCESS'
  A_ISSUE_LICENSE_UNKNOWN = 'ERROR'

  field :file             , type: String
  field :language         , type: String
  field :prod_key         , type: String
  field :version_label    , type: String # pull request number
  field :version_requested, type: String
  field :issue_type       , type: String

  belongs_to :pullrequest

  validates_presence_of :file    , :message => 'is mandatory!'
  validates_presence_of :language, :message => 'is mandatory!'
  validates_presence_of :prod_key, :message => 'is mandatory!'

end

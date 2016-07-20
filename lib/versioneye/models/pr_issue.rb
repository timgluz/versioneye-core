class PrIssue < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SCM_GITHUB     = 'github'

  A_ISSUE_SECURITY        = 'SECURITY'
  A_ISSUE_LICENSE_UNKNOWN = 'LICENSE_UNKNOWN'

  field :file             , type: String
  field :language         , type: String
  field :prod_key         , type: String
  field :version_label    , type: String # pull request number
  field :version_requested, type: String
  field :issue_type       , type: String
  field :message          , type: String

  belongs_to :pullrequest

  validates_presence_of :file    , :message => 'is mandatory!'
  validates_presence_of :language, :message => 'is mandatory!'
  validates_presence_of :prod_key, :message => 'is mandatory!'

end

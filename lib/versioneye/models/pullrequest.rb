class Pullrequest < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SCM_GITHUB     = 'github'
  A_STATUS_SUCCESS = 'SUCCESS'
  A_ERROR_SUCCESS  = 'ERROR'

  field :scm_provider , type: String, :default => A_SCM_GITHUB
  field :scm_fullname , type: String
  field :scm_branch   , type: String
  field :pr_number    , type: String # pull request number
  field :commit_sha   , type: String
  field :tree_sha     , type: String
  field :status       , type: String
  field :security_count, type: String
  field :unknown_license_count, type: String

  validates_presence_of :scm_provider   , :message => 'is mandatory!'
  validates_presence_of :scm_fullname   , :message => 'is mandatory!'

end

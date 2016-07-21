class Pullrequest < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SCM_GITHUB     = 'github'
  A_STATUS_PENDING = 'pending'
  A_STATUS_SUCCESS = 'success'
  A_STATUS_ERROR   = 'error'

  field :commits_url   , type: String
  field :scm_provider  , type: String, :default => A_SCM_GITHUB
  field :scm_fullname  , type: String
  field :scm_branch    , type: String
  field :pr_number     , type: String # pull request number
  field :commit_sha    , type: String
  field :tree_sha      , type: String
  field :status        , type: String, :default => A_STATUS_PENDING
  field :security_count, type: Integer, :default => 0
  field :unknown_license_count, type: Integer, :default => 0
  field :token         , type: String


  validates_presence_of :scm_provider   , :message => 'is mandatory!'
  validates_presence_of :scm_fullname   , :message => 'is mandatory!'

  has_many :pr_issues

  def description
    if security_count == 0 && unknown_license_count == 0
      return "All software dependencies are fine. You are awesome!"
    elsif security_count > 0 && unknown_license_count == 0
      return "Some dependencies have security issues."
    elsif security_count == 0 && unknown_license_count > 0
      return "Some dependencies have no license."
    elsif security_count > 0 && unknown_license_count > 0
      return "There are all kind of security and license issues!"
    end
  end

end

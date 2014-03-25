class SecurityNotification < Versioneye::Model

  include Mongoid::Document

  field :summary, type: String
  field :metrics, type: Hash

  scope :only_reviewed, where(reviewed: true)

end

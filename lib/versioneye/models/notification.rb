class Notification < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_CLASSI_NIL     = nil
  A_CLASSI_XRAY    = 'XRAY'
  A_CLASSI_PROJECT = 'PROJECT'

  A_NOTI_TYPE_EMAIL   = 'email'
  A_NOTI_TYPE_WEBHOOK = 'webhook'

  A_EVENT_TYPE_SECURITY = 'security'
  A_EVENT_TYPE_LICENSE  = 'license'
  A_EVENT_TYPE_VERSION  = 'version'

  belongs_to :user
  belongs_to :product

  field :version_id    , type: String
  field :read          , type: Boolean, default: false
  field :sent_email    , type: Boolean, default: false
  field :email_disabled, type: Boolean, default: false
  field :classification, type: String,  default: A_CLASSI_NIL
  field :sv_name_id    , type: String # Security Vulnerability Name ID
  field :watcher_id    , type: String # ID of the watch object which fired this notification

  field :impacted_files, type: Hash # XRay specific

  field :noti_type,  type: String, default: A_NOTI_TYPE_EMAIL
  field :event_type, type: String, default: A_EVENT_TYPE_VERSION

  field :email, type: String # email recipient
  field :name,  type: String # name of the email recipient

  field :webhook,       type: String
  field :webhook_token, type: String

  index({product_id: 1, user_id: 1, version_id: 1}, { name: "prod_user_vers_index", background: true, unique: true, drop_dups: true })
  index({user_id: 1}, { name: "user_index", background: true})
  index({user_id: 1, sent_email: 1}, { name: "user_unsent_index", background: true})

  scope :no_classification, ->{where(classification: nil)}
  scope :xray             , ->{where(classification: A_CLASSI_XRAY)}
  scope :all_not_sent     , ->{where(sent_email: false)}
  scope :by_user          , ->(user){where(user_id: user.id)}
  scope :by_user_id       , ->(user_id){where(user_id: user_id).desc(:created_at).limit(30)}


  def self.unsent_user_notifications( user )
    by_user( user ).where(sent_email: false, classification: A_CLASSI_NIL)
  end


end

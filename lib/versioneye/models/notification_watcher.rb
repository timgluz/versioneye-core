class NotificationWatcher < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,   type: String
  field :event,  type: String # [security, license, version]
  field :type,   type: String # [email, webhook, rss]
  # config
  field :active, type: Boolean, default: true

  belongs_to :user
  belongs_to :organisation

  has_one  :notification_watcher_config
  has_many :notification_watcher_constraints

  def constraints
    self.notification_watcher_constraints
  end

  def config
    self.notification_watcher_config
  end

end

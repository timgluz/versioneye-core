class NotificationWatcherConstraint < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :type,   type: String # [wildcards, security]
  field :value,  type: String

  belongs_to :notification_watcher

end

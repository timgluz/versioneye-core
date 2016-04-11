class NotificationWatcherConfig < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :email,   type: String
  field :url,     type: String

  belongs_to :notification_watcher

end

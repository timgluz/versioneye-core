class NotificationRegistration

  include Mongoid::Document
  include Mongoid::Timestamps

  field :event,  type: String # [security, license, version]
  field :active, type: Boolean, default: true

  belongs_to :user
  belongs_to :organisation

end

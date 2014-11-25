class UserNotificationSetting < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # Receiving general news from VersionEye. For example about Investments.
  field :newsletter_news,     type: Boolean, default: true

  # Receiving the newsletter about new features
  field :newsletter_features, type: Boolean, default: true

  # Receiving notification emails to packages I follow.
  field :notification_emails, type: Boolean, default: true

  # Receiving notification emails to projects VersionEye is watching for me.
  field :project_emails, type: Boolean, default: true

  belongs_to :user


  def self.fetch_or_create_notification_setting user
    if user.user_notification_setting.nil?
      user.user_notification_setting = UserNotificationSetting.new
      user.save
    end
    user.user_notification_setting
  end


end

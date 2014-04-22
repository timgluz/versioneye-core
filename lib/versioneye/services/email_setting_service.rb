class EmailSettingService < Versioneye::Service

  def self.email_setting
    emailsetting = EmailSetting.first
    emailsetting = EmailSetting.create_default if emailsetting.nil?
    emailsetting
  end

  def self.update_action_mailer_from_db
    update_action_mailer email_setting
  end

  def self.update_action_mailer emailSetting
    ActionMailer::Base.smtp_settings = {
        :address  => emailSetting.address,
        :port  => emailSetting.port,
        :user_name => emailSetting.username,
        :password => emailSetting.password,
        :domain => emailSetting.domain,
        :authentication => emailSetting.authentication,
        :enable_starttls_auto => emailSetting.enable_starttls_auto
      }
  rescue => e
    log.error e.message
    log.error e.messages.join '/n'
  end

end

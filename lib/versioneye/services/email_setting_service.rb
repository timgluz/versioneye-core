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
    settings = {:address  => emailSetting.address, :port  => emailSetting.port}

    settings[:user_name] = emailSetting.username if !emailSetting.username.to_s.empty?
    settings[:password] = emailSetting.password if !emailSetting.password.to_s.empty?
    settings[:domain] = emailSetting.domain if !emailSetting.domain.to_s.empty?
    settings[:authentication] = emailSetting.authentication if !emailSetting.authentication.to_s.empty?
    settings[:enable_starttls_auto] = emailSetting.enable_starttls_auto if !emailSetting.enable_starttls_auto.to_s.empty?

    ActionMailer::Base.smtp_settings = settings
  rescue => e
    log.error e.message
    log.error e.messages.join '/n'
  end

end

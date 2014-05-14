class NewsletterService < Versioneye::Service


  def self.send_newsletter_features
    count = 0
    users = User.all()
    users.each do |user|
      next if user.deleted || user.email_inactive

      uns = UserNotificationSetting.fetch_or_create_notification_setting( user )
      next if uns.newsletter_features == false

      count += self.send_email( user )
    end
    count
  end


  def self.send_email( user )
    NewsletterMailer.newsletter_new_features_email( user ).deliver
    log.info "Sent new feature newsletter to #{user.fullname}"
    1
  rescue => e
    user.email_send_error = e.message
    user.save
    log.error e.message
    log.error e.backtrace.join("\n")
    0
  end


end

class NewsletterService < Versioneye::Service


  def self.send_newsletter_features
    count = 0    
    UserService.all_users_paged do |users|
      users.each do |user|
        next if user.deleted_user || user.email_inactive

        uns = UserNotificationSetting.fetch_or_create_notification_setting( user )
        next if uns.newsletter_features.nil?
        next if uns.newsletter_features == false

        count += self.send_email( user )
      end
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

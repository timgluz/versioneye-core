class NotificationService < Versioneye::Service


  def self.send_notifications
    count = 0
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      count += process_user( id )
    end
    NotificationMailer.status( count ).deliver
    log.info "Send out #{count} notification emails"
    count
  end


  def self.process_user id
    user = User.find_by_id( id )
    return 0 if user.nil?

    if user.deleted || user.email_inactive == true
      self.remove_notifications user
      return 0
    end

    return 1 if self.send_unsend_notifications user
    return 0
  end


  def self.send_unsend_notifications user
    notifications = Notification.unsent_user_notifications user
    return false if notifications.nil? || notifications.empty?

    uns = UserNotificationSetting.fetch_or_create_notification_setting user
    if uns.notification_emails == true
      notifications.sort_by {|notice| [notice.product.language]}
      NotificationMailer.new_version_email( user, notifications ).deliver
      log.info "send notifications for user #{user.fullname}"
      return true
    end

    self.remove_notifications user
    return false
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.remove_notifications user
    notifications = Notification.where( :user_id => user.id )
    notifications.each do |notification|
      log.info " ---- Remove notification for user id: #{user.id} "
      notification.remove
    end
  end


end

class NotificationService < Versioneye::Service


  def self.send_notifications
    count = 0
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      count += process_user( id )
    end
    # NotificationMailer.status( count ).deliver_now
    log.info "Send out #{count} notification emails"
    count
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    0
  end


  def self.process_user id
    user = User.find_by_id( id )
    return 0 if user.nil?

    if user.deleted_user || user.email_inactive == true
      self.remove_notifications user
      return 0
    end

    return 1 if self.send_unsend_notifications( user )
    return 0
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    0
  end


  def self.send_unsend_notifications user
    uns = UserNotificationSetting.fetch_or_create_notification_setting user
    if uns.notification_emails == false
      self.disable_notifications user
      return false
    end

    notifications = Notification.unsent_user_notifications user
    return false if notifications.nil? || notifications.empty?

    notis = uniq_products notifications
    notis.sort_by {|notice| [notice.product.language]}
    NotificationMailer.new_version_email( user, notis ).deliver_now
    log.info "Send notifications to user #{user.fullname}"
    mark_as_sent notifications
    MailTrack.add user.ids, MailTrack::A_TEMPLATE_NEW_VERSION, nil
    return true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.remove_notifications user
    log.info " ---- Remove notifications for #{user.username}"
    notifications = Notification.where( :user_id => user.id.to_s )
    notifications.each do |notification|
      notification.remove
    end
  end

  def self.disable_notifications user
    log.info " ---- Disable notifications for #{user.username}"
    notifications = Notification.by_user(user).all_not_sent
    notifications.each do |notification|
      notification.sent_email = true
      notification.email_disabled = true
      notification.save
    end
  end

  def self.uniq_products notifications
    hashi = Hash.new
    notifications.each do |noti|
      next if noti.nil? || noti.product_id.nil? || noti.version_id.nil?
      hashi[noti.product_id] = [] if hashi[noti.product_id].nil?
      hashi[noti.product_id] << noti.version_id
    end

    hashi.each do |product_id, version_ids|
      if version_ids.count > 1
        hashi[product_id] = [ VersionService.newest_version( version_ids ) ]
      end
    end

    result = []
    notifications.each do |noti|
      version_id = hashi[noti.product_id].first
      if version_id.eql?(noti.version_id)
        result << noti
      end
    end
    result
  end

  def self.mark_as_sent notifications
    notifications.each do |notification|
      notification.sent_email = true
      notification.email_disabled = false
      notification.save
    end
  end

end

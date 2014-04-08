class NotificationService < Versioneye::Service


  def self.send_notifications
    count = 0
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      user = User.find_by_id( id )
      next if user.nil?

      if user.deleted
        self.remove_notifications user
      else
        count += 1 if self.send_unsend_notifications user
      end
    end
    NotificationMailer.status( count ).deliver
    log.info "Send out #{count} emails"
    count
  end


  def self.send_unsend_notifications user
    notifications = Notification.unsent_user_notifications user
    return false if notifications.nil? || notifications.empty?

    notifications.sort_by {|notice| [notice.product.language]}
    NotificationMailer.new_version_email( user, notifications ).deliver
    log.info "send notifications for user #{user.fullname} start"
    return true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.remove_notifications user
    log.info " -- No user found for id: #{user.id} "
    notifications = Notification.where( :user_id => user.id )
    notifications.each do |notification|
      log.info " ---- Remove notification for user id: #{user.id} "
      notification.remove
    end
  end


end

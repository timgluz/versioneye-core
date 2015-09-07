class SecurityNotificationService < Versioneye::Service


  def self.process
    user_ids = Project.where(:sv_count.gt => 0).distinct(:user_id)
    user_ids.each do |user_id|
      process_user user_id
    end
  end


  def self.process_user user_id
    user = User.find user_id
    return nil if user.nil?
    return nil if user.deleted_user == true
    return nil if user.email_inactive == true

    uns = UserNotificationSetting.fetch_or_create_notification_setting( user )
    return nil if uns.project_emails == false

    period = Project::A_PERIOD_WEEKLY
    return nil if MailTrack.send_already? user.ids, MailTrack::A_TEMPLATE_PROJECT_SV, period

    projects = Project.where(:sv_count.gt => 0, :user_id => user_id)
    return nil if projects.nil? || projects.empty?

    ProjectMailer.security_email( user, projects ).deliver_now
    MailTrack.add user.ids, MailTrack::A_TEMPLATE_PROJECT_SV, period
    true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


end

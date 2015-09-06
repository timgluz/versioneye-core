class ProjectBatchUpdateService < Versioneye::Service

=begin
  This method iterates through all users and sends out
  a project notification email to each user. The project notification email
  contains a status list with all projects of the user.  The list
  includes projects which belong to the user and projects where
  the user is collaborator.
=end
  def self.update_all period
    project_ids = [] # temp. project_id cache to avoid parsing the same project twice.
    UserService.all_users_paged do |users|
      update_for users, period, project_ids
    end
    project_ids
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_for users, period, project_ids = nil
    return nil if users.nil? || users.empty?

    users.each do |user|
      process user, period, project_ids
    end
  end


  def self.process user, period, project_ids = nil
    return nil if user.nil?
    return nil if user.deleted_user == true
    return nil if user.email_inactive == true

    uns = UserNotificationSetting.fetch_or_create_notification_setting( user )
    return nil if uns.project_emails == false

    return nil if MailTrack.send_already? user.ids, MailTrack::A_TEMPLATE_PROJECT_NOTI, period

    perform_update user, period, project_ids

    projects     = fetch_affected_projects user, period
    col_projects = fetch_affected_collaboration_projects user, period
    return nil if (projects.nil? || projects.empty?) && (col_projects.nil? || col_projects.empty?)

    ProjectMailer.projectnotifications_email( user, projects, col_projects, period ).deliver_now
    MailTrack.add user.ids, MailTrack::A_TEMPLATE_PROJECT_NOTI, period
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  # Update the projects. Re parse the project files and update the numbers!
  def self.perform_update user, period, project_ids = nil
    projects     = fetch_projects user, period
    col_projects = fetch_collaboration_projects user, period
    return nil if (projects.nil? || projects.empty?) && (col_projects.nil? || col_projects.empty?)

    log.info "process #{period} projects for #{user.fullname}"
    update_projects projects, false, project_ids
    update_projects col_projects, false, project_ids
  end


  def self.update_projects projects, send_email = false, project_ids = nil
    return nil if projects.nil? || projects.empty?

    projects.each do |project|
      next if project_ids && project_ids.include?(project.ids)

      ProjectUpdateService.update project, send_email
      project_ids.push(project.ids) if project_ids
    end
  end


  private


    def self.fetch_projects user, period
      return [] if user.projects.nil? || user.projects.empty?

      user.projects.by_period( period ).parents
    end


    def self.fetch_affected_projects user, period
      return [] if user.projects.nil? || user.projects.empty?

      user.projects.by_period( period ).parents.any_of({:out_number_sum.gt => 0},{:licenses_red_sum.gt => 0})
    end


    def self.fetch_collaboration_projects user, period
      collaborations = ProjectCollaborator.by_user( user ).where(:period => period)
      projects = []
      collaborations.each do |collab|
        if collab.project.nil?
          collab.remove
          next
        end
        projects << collab.project
      end
      projects
    end


    def self.fetch_affected_collaboration_projects user, period
      projects = []
      pros = fetch_collaboration_projects user, period
      pros.each do |project|
        projects << project if project.licenses_red_sum > 0 || project.out_number_sum > 0
      end
      projects
    end

end

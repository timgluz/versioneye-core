class ProjectBatchUpdateService < Versioneye::Service

=begin
  This method iterates through all users and sends out 
  a project notification email to each user. The project notification email 
  contains a status list with all projects of the user.  The list 
  includes projects which belong to the user and projects where 
  the user is collaborator.
=end
  def self.update_all period
    UserService.all_users_paged do |users|
      update_for users, period
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.update_for users, period
    return nil if users.nil? || users.empty?

    users.each do |user|
      process user, period
    end
  end


  def self.process user, period
    return nil if user.nil?
    return nil if user.deleted_user == true
    return nil if user.email_inactive == true

    uns = UserNotificationSetting.fetch_or_create_notification_setting( user )
    return nil if uns.project_emails == false

    projects = fetch_projects user, period
    col_projects = fetch_collaboration_projects user, period
    return nil if (projects.nil? || projects.empty?) && col_projects.empty?

    log.info "process #{period} projects for #{user.fullname}"
    update_projects projects, false
    update_projects col_projects, false 

    ProjectMailer.projectnotifications_email( user, projects, col_projects, period ).deliver
  end


  def self.update_projects projects, send_email = false
    return nil if projects.nil? || projects.empty?

    projects.each do |project|
      msg = "project_#{project.id.to_s}:::#{send_email}"
      ProjectUpdateProducer.new( msg )
    end
  end


  private


    def self.fetch_projects user, period
      return [] if user.projects.nil? || user.projects.empty?

      user.projects.by_period( period ).parents
    end


    def self.fetch_collaboration_projects user, period
      collaborations = ProjectCollaborator.by_user( user ).where(:period => period)
      projects = []
      collaborations.each do |collab|
        if collab.project
          projects << collab.project 
        else
          log.error "Collaborated project doesnt exists: `#{collab.to_json}`"
          collab.remove
        end
      end
      projects
    end

end

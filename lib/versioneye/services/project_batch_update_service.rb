class ProjectBatchUpdateService < Versioneye::Service

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
    return nil if user.deleted == true
    return nil if user.email_inactive == true

    projects = fetch_projects user, period
    col_projects = fetch_collaboration_projects user, period
    return nil if (projects.nil? || projects.empty?) && col_projects.empty?

    projects.each do |project|
      ProjectUpdateService.update project, false
    end

    col_projects.each do |project|
      ProjectUpdateService.update project, false
    end

    ProjectMailer.projectnotifications_email(user, projects, col_projects, period).deliver
  end


  private


    def self.fetch_projects user, period
      return [] if user.projects.nil? || user.projects.empty?

      user.projects.where(:period => period)
    end


    def self.fetch_collaboration_projects user, period
      collaborations = ProjectCollaborator.by_user( user ).where(:period => period)
      projects = []
      collaborations.each do |collab|
        if collab.project
          projects << collab.project
        else
          logger.error "Collaborated project doesnt exists: `#{collab.to_json}`"
          collab.remove
        end
      end
      projects
    end

end

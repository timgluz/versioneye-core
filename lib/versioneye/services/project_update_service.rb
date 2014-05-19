class ProjectUpdateService < Versioneye::Service


  def self.update_all period
    update_projects period
    update_collaborators_projects period
  end


  def self.update_projects period
    projects = Project.by_period period
    projects.each do |project|
      self.update( project, true )
    end
  end


  def self.update_collaborators_projects period
    collaborators = ProjectCollaborator.by_period( period )
    collaborators.each do |collaborator|
      project = collaborator.project
      user    = collaborator.user
      if project.nil? || user.nil?
        collaborator.remove
        next
      end
      project = self.update( project, false )
      if project.out_number > 0
        log.info "send out email notification to collaborator #{user.fullname} for #{project.name}."
        ProjectMailer.projectnotification_email( project, user ).deliver
      end
    end
  end


  def self.update project, send_email = false
    return nil if project.nil?
    return nil if project.user_id.nil? || project.user.nil?
    return nil if project.user.deleted

    updater = UpdateStrategy.updater_for project.source
    updater.update project, send_email
    project
  rescue => e
    log.error e.message
    nil
  end


  def self.update_from_upload project, file, user = nil, api_created = false
    return nil if project.nil?

    new_project = ProjectParseService.project_from file
    project.update_from new_project
    project.api_created = api_created
    project
  end


end

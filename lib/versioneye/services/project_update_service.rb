class ProjectUpdateService < Versioneye::Service


  def self.update_async project, send_email = false 
    return nil if not_updateable?( project )
    
    msg = "project_#{project.id.to_s}:::#{send_email}"
    ProjectUpdateProducer.new( msg )
  end


  def self.update project, send_email = false
    return nil if not_updateable?( project )

    project = update_single project, send_email 
    project.children.each do |child_project|
      update_single child_project, send_email   
    end
    ProjectService.update_sums( project )
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.update_single project, send_email = false
    return nil if not_updateable?( project )

    updater = UpdateStrategy.updater_for project.source
    updater.update project, send_email
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.update_from_upload project, file, user = nil, api_created = false
    return nil if project.nil?

    new_project = ProjectParseService.project_from file
    cache.delete( new_project.id.to_s )
    project.update_from new_project
    project.api_created = api_created
    ProjectService.update_license_numbers! project 
    update_numbers project

    project
  end


  private 


    def self.update_numbers project 
      if !project.parent_id.to_s.empty?
        ProjectService.update_sums project.parent 
      end
    rescue => e 
      log.error e.message
      log.error e.backtrace.join("\n")  
    end


    def self.not_updateable?( project )
      return true if project.nil?
      return true if project.user_id.nil? || project.user.nil?
      return true if project.user.deleted_user == true  
      return false 
    end


end

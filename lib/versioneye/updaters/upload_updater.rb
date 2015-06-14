class UploadUpdater < CommonUpdater

  def update( project, send_email = false )
    return nil if project.nil?
    
    out_number = 0 
    dep_number = 0 
    project.dependencies.each do |dep|
      outdated = ProjectdependencyService.outdated?( dep )
      out_number += 1 if outdated
      dep_number += 1 
    end
    project.reload

    cache.delete( project.id.to_s ) # Delete badge status for project

    SyncService.sync_project_async project # For Enterprise environment

    ProjectdependencyService.update_licenses_security project
    
    unknown_licenses = ProjectService.unknown_licenses( project )
    red_licenses     = ProjectService.red_licenses( project )
    project.licenses_red = red_licenses.count
    project.licenses_unknown = unknown_licenses.count
    project.dep_number = dep_number
    project.out_number = out_number
    project.sum_own! 

    return project if send_email == false 
    return project if project.user.email_inactive == false

    outdated_deps  = project.out_number > 0
    # The next line is commented out because right now the user can not edit licenses
    # license_alerts = !unknown_licenses.empty? || !red_licenses.empty?
    license_alerts = !red_licenses.empty?

    if ( outdated_deps || license_alerts )
      log.info "Send out email notification for project #{project.name} to user #{project.user.fullname}"
      ProjectMailer.projectnotification_email( project, nil, unknown_licenses, red_licenses ).deliver
    end

    project
  end

end

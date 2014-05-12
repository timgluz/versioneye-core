class UploadUpdater

  def update( project, send_email = false )
    project.dependencies.each do |dep|
      ProjectdependencyService.outdated?( dep )
    end

    project.reload
    if send_email && project.out_number > 0 && project.user.email_inactive == false
      log.info "Send out email notification for project #{project.name} to user #{project.user.fullname}"
      ProjectMailer.projectnotification_email( project ).deliver
    end

    project
  end

end

class CommonUpdater < Versioneye::Service


  def update_old_with_new old_project, new_project, send_email = false
    return nil if old_project.nil? || new_project.nil?

    old_project.update_from new_project
    ProjectService.reset_badge old_project

    SyncService.sync_project_async old_project # For Enterprise environment

    ProjectdependencyService.update_licenses_security old_project

    unknown_licenses = ProjectService.unknown_licenses( old_project )
    red_licenses     = ProjectService.red_licenses( old_project )
    old_project.licenses_red = red_licenses.count
    old_project.licenses_unknown = unknown_licenses.count
    old_project.save

    active_email   = send_email && old_project.user && old_project.user.email_inactive == false
    outdated_deps  = old_project.out_number > 0
    # The next line is commented out because right now the user can not edit licenses
    # license_alerts = !unknown_licenses.empty? || !red_licenses.empty?
    license_alerts = old_project.licenses_red.to_i > 0

    if active_email && ( outdated_deps || license_alerts )
      log.info "Send out email notification for project #{old_project.name} to user #{old_project.user.fullname}"
      ProjectMailer.projectnotification_email( old_project, nil, unknown_licenses, red_licenses ).deliver_now
    end
  end


  def store_parsing_errors project, error_message
    return nil if project.nil? || error_message.to_s.empty?

    project.parsing_errors = []
    project.parsing_errors << error_message

    project.save
  rescue => e
    log.error "ERROR occured store_parsing_errors - #{e.message}"
    log.error e.backtrace.join("\n")
  end


  def user_for project
    return project.user if project.user
    if project.teams && !project.teams.empty?
      return project.teams.first.members.first.user
    end
    nil
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  private


    def log
      Versioneye::Log.instance.log
    end

    def self.log
      Versioneye::Log.instance.log
    end

    def cache
      Versioneye::Cache.instance.mc
    end

    def self.cache
      Versioneye::Cache.instance.mc
    end

    def parser_for file_name
      ProjectParseService.parser_for file_name
    end

    def parse_content parser, content, file_name
      ProjectParseService.parse_content parser, content, file_name
    end


end

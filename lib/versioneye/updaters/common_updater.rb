class CommonUpdater < Versioneye::Service


  def update_old_with_new old_project, new_project, send_email = false
    old_project.update_from new_project
    old_project.reload
    cache.delete( old_project.id.to_s ) # Delete badge status for project
    if send_email && old_project.out_number > 0 && old_project.user.email_inactive == false
      log.info "Send out email notification for project #{old_project.name} to user #{old_project.user.fullname}"
      ProjectMailer.projectnotification_email( old_project ).deliver
    end
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

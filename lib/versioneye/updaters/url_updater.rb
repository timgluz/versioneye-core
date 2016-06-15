class UrlUpdater < CommonUpdater


  def update( project, send_email = false )
    return nil if project.nil?
    return nil if project.url.to_s.empty?

    parser = parser_for project.url
    log.info "parser: #{parser.to_s}"
    if parser.nil?
      log.error "No parser found for project (#{project.id}) url: #{project.url}"
      return nil
    end

    new_project = parser.parse project.url
    if new_project.nil?
      store_errors project
      return nil
    end

    new_project.url = project.url
    update_old_with_new project, new_project, send_email
  rescue => e
    log.error "ERROR occured by parsing #{project.url} - #{e.message}"
    log.error e.backtrace.join("\n")
    store_errors project
  end


  private


    def store_errors project
      message = "Project could not be parsed from URL: #{project.url}. Please make sure that the URL exists."
      store_parsing_errors project, message
    end


end

class UrlUpdater < CommonUpdater

  
  def update( project, send_email = false )
    return nil if project.nil?
    return nil if project.url.to_s.empty? 

    parser = parser_for project.url
    if parser.nil?
      log.error "No parser found for project (#{project.id}) url: #{project.url}"
      return
    end

    new_project = parser.parse project.url
    new_project.url = project.url
    update_old_with_new project, new_project, send_email
  rescue => e
    log.error "ERROR occured by parsing #{project.url} - #{e.message}"
    log.error e.backtrace.join("\n")
    message = "Project could not be parsed from URL: #{project.url}. Please make sure that the URL exists."
    store_parsing_errors project, message
  end


end

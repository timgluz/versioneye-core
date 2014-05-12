class UrlUpdater < CommonUpdater

  def update( project, send_email = false )
    parser = parser_for project.url
    new_project = parser.parse project.url
    update_old_with_new project, new_project, send_email
  end

end

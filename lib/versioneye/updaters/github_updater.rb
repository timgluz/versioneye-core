class GithubUpdater < CommonUpdater


  def update project, send_email = false
    project_file = fetch_project_file project
    if project_file.to_s.strip.empty?
      log.error "Importing project file from Github failed."
      return nil
    end

    new_project = parse project_file
    update_old_with_new project, new_project, send_email
  end


  def fetch_project_file project
    filename = project.filename
    filename = 'pom.xml' if filename.eql? 'pom.json'
    Github.fetch_project_file_from_branch project.scm_fullname, filename, project.scm_branch, project.user.github_token
  end


  def parse project_file
    fullname  = project_file[:name]
    file_name = fullname.split("/").last
    parser    = parser_for file_name
    content   = Base64.decode64( project_file[:content] )
    parse_content parser, content, file_name
  end


end

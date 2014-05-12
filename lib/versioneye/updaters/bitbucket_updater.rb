class BitbucketUpdater < CommonUpdater


  def update project, send_email = false 
    project_file = fetch_project_file project
    if project_file.to_s.empty? || project_file.match("you've found a dead link")
      log.error "Importing project file from Bitbucket failed."
      return nil
    end

    new_project = parse project_file, project.filename
    update_old_with_new project, new_project, send_email
  end


  def fetch_project_file project
    user = project.user
    filename = project.filename
    filename = 'pom.xml' if filename.eql? 'pom.json'
    repo_name = project.scm_fullname
    branch = project.scm_branch
    token = user.bitbucket_token
    secret = user.bitbucket_secret
    Bitbucket.fetch_project_file_from_branch( repo_name, branch, filename, token, secret )
  end


  def parse project_file, fullname
    file_name = fullname.split("/").last
    parser = parser_for file_name
    parse_content parser, project_file, file_name
  end


end

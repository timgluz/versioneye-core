class BitbucketUpdater < CommonUpdater


  def update project, send_email = false
    project.parsing_errors = []
    project_file = fetch_project_file project
    if project_file.to_s.empty? || project_file.match("you've found a dead link")
      message = "Project could not be parsed from the Bitbucket API. Please make sure that the credentials are still valid and the repository still exists."
      log.error message
      store_parsing_errors project, message
      return nil
    end

    new_project = parse project_file, project.filename
    update_old_with_new project, new_project, send_email
  rescue => e
    log.error "ERROR occured by parsing project from Bitbucket API - #{e.message}"
    log.error e.backtrace.join("\n")
    message = "Project could not be parsed from the Bitbucket API. Please make sure that the credentials are still valid and the repository still exists. - #{e.message}"
    store_parsing_errors project, message
  end


  def fetch_project_file project
    user = user_for project
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

class GithubUpdater < CommonUpdater


  def update project, send_email = false
    project.parsing_errors = []
    token = fetch_token_for project
    project_file = fetch_project_file project, token
    if project_file.to_s.strip.empty?
      store_errors project
      return nil
    end

    new_project = ProjectImportService.create_project_from project_file, token
    update_old_with_new project, new_project, send_email
  rescue => e
    log.error "ERROR occured by parsing project from GitHub API - #{e.message}"
    log.error e.backtrace.join("\n")
    store_errors project
  end


  def fetch_token_for project
    user = user_for project
    return user.github_token if user
    nil
  rescue => e
    log.error "ERROR occured in fetch_token_for #{project.to_s} - #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end


  def fetch_project_file project, token = nil
    filename = project.filename
    filename = 'pom.xml' if filename.eql? 'pom.json'
    Github.fetch_project_file_from_branch project.scm_fullname, filename, project.scm_branch, token
  end


  private


    def store_errors project
      message = "Project could not be parsed from the GitHub API. Please make sure that the credentials are still valid and the repository still exists."
      log.error message
      store_parsing_errors project, message
    end


end

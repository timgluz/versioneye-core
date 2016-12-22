class StashUpdater < CommonUpdater


  def update project
    project.parsing_errors = []
    project_file = fetch_project_file project
    if project_file.to_s.strip.empty?
      store_errors project
      return nil
    end

    filename    = fetch_filename project
    new_project = StashService.parse_content project_file, filename
    update_old_with_new project, new_project
  rescue => e
    log.error "ERROR occured by parsing project from Stash API - #{e.message}"
    log.error e.backtrace.join("\n")
    store_errors project
  end


  def fetch_project_file project
    user         = user_for project
    repo_name    = project.scm_fullname
    repo         = StashRepo.by_user( user ).by_fullname( repo_name ).shift
    filename     = fetch_filename project
    branch       = project.scm_branch
    project_file = StashService.fetch_file_from_stash(user, repo, filename, branch)
    err_message  = error_message(project_file)
    if !err_message.to_s.empty?
      log.error err_message
      return nil
    end
    StashService.pure_text_from project_file
  end


  def fetch_filename project
    filename = project.filename
    filename = 'pom.xml' if filename.eql? 'pom.json'
    filename
  end


  def error_message project_file
    project_file[:errors].first[:message]
  rescue => e
    ''
  end


  private


    def store_errors project
      message = "Project could not be parsed from the Stash API. Please make sure that the credentials are still valid and the repository still exists."
      log.error message
      store_parsing_errors project, message
    end


end

class StashUpdater < CommonUpdater


  def update project, send_email = false
    project_file = fetch_project_file project
    if project_file.to_s.strip.empty?
      log.error "Importing project file from Github failed."
      return nil
    end

    filename    = fetch_filename project
    new_project = StashService.parse_content project_file, filename
    update_old_with_new project, new_project, send_email
  end


  def fetch_project_file project
    user         = project.user
    repo_name    = project.scm_fullname
    repo         = StashRepo.by_user( user ).by_fullname( repo_name ).shift
    filename     = fetch_filename project
    branch       = project.scm_branch
    project_file = StashService.fetch_file_from_stash(user, repo, filename, branch)
    StashService.pure_text_from project_file
  end


  def fetch_filename project
    filename = project.filename
    filename = 'pom.xml' if filename.eql? 'pom.json'
    filename
  end


end

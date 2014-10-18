class StashUpdater < CommonUpdater

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
    user        = project.user
    repo_name   = project.scm_fullname
    repo        = StashRepo.by_user( user ).by_fullname( repo_name ).shift
    project_key = repo.project_key
    slug        = repo.slug
    token       = user.stash_token
    secret      = user.stash_secret
    filename    = project.filename
    filename    = 'pom.xml' if filename.eql? 'pom.json'
    branch      = project.scm_branch
    revision = "refs/heads/#{branch}"
    Stash.content(project_key, slug, filename, revision, token, secret)
  end


end

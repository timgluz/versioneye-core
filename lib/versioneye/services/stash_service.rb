class StashService < Versioneye::Service

  A_TASK_NIL     = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE    = 'done'
  A_TASK_TTL     = 600 # 600 seconds = 10 minutes
  A_TASK_TTL_DONE = 180 # 180 seconds = 3 minutes


  def self.cached_user_repos user
    user_task_key = "#{user[:username]}-stash"
    task_status = cache.get(user_task_key)

    if task_status == A_TASK_RUNNING || task_status == A_TASK_DONE
      log.debug "Status for #{user[:username]} from stash is -> #{task_status}"
      return task_status
    end

    if user[:stash_token] and user.stash_repos.all.count == 0
      GitReposImportProducer.new("stash:::#{user.id.to_s}")
      task_status =  A_TASK_RUNNING
    else
      log.info "Nothing to import - maybe clean user's repo?"
      task_status = A_TASK_DONE
    end

    cache.set( user_task_key, task_status, A_TASK_TTL_DONE )
    task_status
  end


  def self.cache_user_all_repos( user )
    puts "Going to cache users repositories."

    repos = Stash.all_repos user.stash_token, user.stash_secret
    return nil if repos.nil? || repos.empty?

    repos.each do |repo|
      StashRepo.build_or_update user, repo
    end
  end


  def self.status_for user, current_repo
    return A_TASK_DONE if current_repo.nil?

    repo_task_key = "stash:::#{user.id.to_s}:::#{current_repo.id.to_s}"
    task_status   = cache.get( repo_task_key )
    if task_status == A_TASK_RUNNING || task_status == A_TASK_DONE
      repo_fullname = current_repo.fullname
      log.debug "Status for importing branches and project files for `#{repo_fullname}.` is -> : #{task_status}"
      return task_status
    end

    if current_repo and ( current_repo.branches.nil? || current_repo.branches.empty? )
      task_status = A_TASK_RUNNING
      cache.set( repo_task_key, task_status, A_TASK_TTL )
      GitRepoImportProducer.new( repo_task_key )
    else
      log.info 'Nothing is changed - skipping update.'
      task_status = A_TASK_DONE
    end

    task_status
  end


  def self.update_branches user, repo
    project_key = repo.project_key
    slug = repo.slug
    token = user.stash_token
    secret = user.stash_secret
    repo.branches = Stash.branch_names project_key, slug, token, secret
    repo.save
  end


  def self.update_project_files user, repo
    return nil if repo.nil? 
    return nil if repo.branches.nil?

    project_files = {}
    project_key = repo.project_key
    repo_name = repo.slug
    token = user.stash_token
    secret = user.stash_secret
    repo.branches.each do |branch_name|
      files = Stash.files( project_key, repo_name, branch_name, token, secret )
      supported = filter_supported files[:values]
      next if supported.empty?

      branch_key = Stash.encode_db_key( branch_name )
      project_files[branch_key] = supported
    end
    repo.project_files = project_files
    repo.save
  end


  def self.filter_supported files
    supported = []
    files.each do |file|
      type = ProjectService.type_by_filename file
      next if type.to_s.empty?

      supported << {"path" => file}
    end
    supported
  end


  # Returns the file as JSON.
  # Use the `pure_text_from` method to get the text content.
  def self.fetch_file_from_stash( user, repo, filename, branch )
    token       = user.stash_token
    secret      = user.stash_secret
    project_key = repo.project_key
    slug        = repo.slug
    revision    = "refs/heads/#{branch}"
    Stash.content( project_key, slug, filename, revision, token, secret )
  end


  def self.pure_text_from project_file
    content = ""
    project_file[:lines].each do |line|
      content += line[:text]
      content += "\n"
    end
    content
  end


  # Parses the content of a project file and returns a
  # project created out of the project file content!
  def self.parse_content content, filename
    project_type = ProjectService.type_by_filename filename
    file_name    = filename.split("/").last
    parser       = ProjectParseService.parser_for file_name
    project      = ProjectParseService.parse_content parser, content, file_name
    project
  end


end

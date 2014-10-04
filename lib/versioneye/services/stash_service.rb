class StashService < Versioneye::Service

  A_TASK_NIL     = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE    = 'done'
  A_TASK_TTL     = 600 # 600 seconds = 10 minutes
  A_TASK_TTL_DONE = 180 # 180 seconds = 3 minutes


  def self.cached_user_repos user
    user_task_key = "#{user[:username]}-stash"
    task_status = cache.get(user_task_key)

    if task_status == A_TASK_RUNNING
      log.debug "Still importing data for #{user[:username]} from stash"
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
    if task_status == A_TASK_RUNNING
      repo_fullname = current_repo.fullname
      log.debug "We are still importing branches and project files for `#{repo_fullname}.`"
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
    project_files = {}
    project_key = repo.project_key
    repo_name = repo.slug
    token = user.stash_token
    secret = user.stash_secret
    repo.branches.each do |branch_name|
      files = Stash.files( project_key, repo_name, branch_name, token, secret )
      supported = filter_supported files[:values]
      next if supported.empty?

      project_files[branch_name] = supported
    end
    repo.project_files = project_files
    repo.save
  end


  def self.filter_supported files
    supported = []
    files.each do |file|
      type = ProjectService.type_by_filename file
      next if type.to_s.empty?

      supported << file
    end
    supported
  end


end

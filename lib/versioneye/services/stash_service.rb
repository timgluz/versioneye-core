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


end

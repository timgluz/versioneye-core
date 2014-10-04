class StashService < Versioneye::Service

  A_TASK_NIL     = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE    = 'done'
  A_TASK_TTL     = 600 # 600 seconds = 10 minutes


  def self.cached_user_repos user
    user_task_key = "#{user[:username]}-stash"
    task_status = cache.get(user_task_key)

    if task_status == A_TASK_RUNNING
      log.debug "Still importing data for #{user[:username]} from Stash"
      return task_status
    end

    if user[:stash_token] and user.stash_repos.all.count == 0
      task_status =  A_TASK_RUNNING
      cache.set( user_task_key, task_status, A_TASK_TTL )
      BitbucketReposImportProducer.new("#{user.id.to_s}")
    else
      log.info "Nothing to import - maybe clean user's repo?"
      task_status = A_TASK_DONE
    end

    task_status
  end



end

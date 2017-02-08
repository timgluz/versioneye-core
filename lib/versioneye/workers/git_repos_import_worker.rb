class GitReposImportWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("git_repos_import", :durable => true)

    multi_log " [*] GitReposImportWorker Waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] GitReposImportWorker received #{body}"
        import_all_repos body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] GitReposImportWorker job done #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  private


    def import_all_repos msg
      reload_settings()
      provider = msg.split(":::").first
      user_id = msg.split(":::").last
      user = User.find user_id

      multi_log "   [x] GitReposImportWorker going to import repos for #{user.username} from provider #{provider}"

      if provider.eql?("stash")
        import_stash_repos( user )
      elsif provider.eql?("github")
        import_github_repos( user )
      elsif provider.eql?("bitbucket")
        import_bitbucket_repos( user )
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


    def import_github_repos user
      return nil if user.nil?

      user_task_key = "#{user[:username]}-#{user[:github_id]}"
      multi_log "   [x] GitReposImportWorker fetch Repositories for #{user_task_key} from GitHub and cache them in DB."

      cache.set( user_task_key, GitHubService::A_TASK_RUNNING, GitHubService::A_TASK_TTL )
      orga_names = Github.orga_names( user.github_token )
      GitHubService.cache_user_all_repos(user, orga_names)
      cache.set( user_task_key, GitHubService::A_TASK_DONE, GitHubService::A_TASK_TTL )
    rescue => e
      log.error "ERROR in import_github_repos for user #{user} - e.message"
      log.error e.backtrace.join("\n")
    end


    def import_bitbucket_repos user
      return nil if user.nil?

      user_task_key = "#{user[:username]}-bitbucket"
      multi_log "   [x] GitReposImportWorker fetch Repositories for #{user_task_key} from Bitbucket and cache them in DB."

      cache.set( user_task_key, BitbucketService::A_TASK_RUNNING, BitbucketService::A_TASK_TTL )
      BitbucketService.cache_user_all_repos( user )
      cache.set( user_task_key, BitbucketService::A_TASK_DONE, BitbucketService::A_TASK_TTL )
    rescue => e
      log.error "ERROR in import_bitbucket_repos for user #{user} - e.message"
      log.error e.backtrace.join("\n")
    end


    def import_stash_repos user
      return nil if user.nil?

      user_task_key = "#{user[:username]}-stash"
      multi_log "   [x] GitReposImportWorker fetch Repositories for #{user_task_key} from Stash and cache them in DB."

      cache.set( user_task_key, StashService::A_TASK_RUNNING, StashService::A_TASK_TTL )
      StashService.cache_user_all_repos( user )
      cache.set( user_task_key, StashService::A_TASK_DONE, StashService::A_TASK_TTL )
    rescue => e
      log.error "ERROR in import_stash_repos for user #{user} - e.message"
      log.error e.backtrace.join("\n")
    end


end

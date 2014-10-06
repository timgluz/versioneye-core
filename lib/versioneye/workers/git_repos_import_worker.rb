class GitReposImportWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("git_repos_import", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        import_all_repos body

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  private

    def import_all_repos msg
      provider = msg.split(":::").first
      user_id = msg.split(":::").last
      user = User.find user_id

      log_msg = "going to import repos for #{user.username} from provider #{provider}"
      log.info log_msg
      p log_msg

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


    def import_stash_repos user
      return nil if user.nil?

      user_task_key = "#{user[:username]}-stash"

      log_msg = "Fetch Repositories for #{user_task_key} from Stash and cache them in DB."
      log.info log_msg
      p log_msg

      cache.set( user_task_key, StashService::A_TASK_RUNNING, StashService::A_TASK_TTL )
      StashService.cache_user_all_repos( user )
      cache.set( user_task_key, StashService::A_TASK_DONE, StashService::A_TASK_TTL )

      log_msg = "Job done for #{user_task_key}"
      log.info log_msg
      p log_msg
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


    def import_github_repos user
      return nil if user.nil?

      user_task_key = "#{user[:username]}-#{user[:github_id]}"
      log.info "Fetch Repositories for #{user_task_key} from GitHub and cache them in DB."

      n_repos    = Github.count_user_repos user # Repos without Orgas
      orga_names = Github.orga_names(user.github_token)

      if n_repos == 0 && orga_names.empty?
        msg = "User #{user.username} has no repositories;"
        puts msg
        log.info msg
        cache.set( user_task_key, GitHubService::A_TASK_DONE, GitHubService::A_TASK_TTL )
        return
      end

      cache.set( user_task_key, GitHubService::A_TASK_RUNNING, GitHubService::A_TASK_TTL )
      GitHubService.cache_user_all_repos(user, orga_names)
      cache.set( user_task_key, GitHubService::A_TASK_DONE, GitHubService::A_TASK_TTL )
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


    def import_bitbucket_repos user
      return nil if user.nil?

      user_task_key = "#{user[:username]}-bitbucket"
      log.info "Fetch Repositories for #{user_task_key} from Bitbucket and cache them in DB."

      cache.set( user_task_key, BitbucketService::A_TASK_RUNNING, BitbucketService::A_TASK_TTL )
      BitbucketService.cache_user_all_repos( user )
      cache.set( user_task_key, BitbucketService::A_TASK_DONE, BitbucketService::A_TASK_TTL )
      log.info "Job done for #{user_task_key}"
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end

class GithubReposImportWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("github_repos_import", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        puts " [x] Received #{body}"
        user = User.find body
        import_all_repos_for user
        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def import_all_repos_for user
    return nil if user.nil?

    user_task_key = "#{user[:username]}-#{user[:github_id]}"
    log.info "Fetch Repositories for #{user_task_key} from GitHub and cache them in DB."

    n_repos    = Github.count_user_repos user # Repos without Orgas
    orga_names = Github.orga_names(user.github_token)

    if n_repos == 0 && orga_names.empty?
      log.debug "User #{user.username} has no repositories;"
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


end

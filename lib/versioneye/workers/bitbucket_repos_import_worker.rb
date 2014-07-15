class BitbucketReposImportWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("bitbucket_repos_import", :durable => true)

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
      log.error e.backtrace.join('\n')
      connection.close
    end
  end


  def import_all_repos_for user
    return nil if user.nil?

    user_task_key = "#{user[:username]}-bitbucket"
    log.info "Fetch Repositories for #{user_task_key} from Bitbucket and cache them in DB."

    cache.set( user_task_key, BitbucketService::A_TASK_RUNNING, BitbucketService::A_TTL )
    BitbucketService.cache_user_all_repos( user )
    cache.set( user_task_key, BitbucketService::A_TASK_DONE, BitbucketService::A_TTL )
    log.info "Job done for #{user_task_key}"
  end


end

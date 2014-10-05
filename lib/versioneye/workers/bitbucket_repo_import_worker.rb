
# TODO remove this class
class BitbucketRepoImportWorker < Worker

  A_TASK_TTL = 180 # 180 seconds = 3 minutes

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("bitbucket_repo_import", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        handle body
        cache.set( body, BitbucketService::A_TASK_DONE, A_TASK_TTL )
        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def handle message
    user_id = message.split(":::").first
    repo_id = message.split(":::").last
    user = User.find user_id
    repo = BitbucketRepo.find repo_id
    update_repo user, repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def update_repo user, repo
    time = Benchmark.measure do
      repo = Bitbucket.update_branches      repo, user.bitbucket_token, user.bitbucket_secret
      repo = Bitbucket.update_project_files repo, user.bitbucket_token, user.bitbucket_secret
      repo.user_id = user.id
      repo.save
    end
    name = repo[:full_name]
    name = repo[:fullname] if name.to_s.empty?

    log_msg = "Reading `#{name}` took: #{time}"
    puts log_msg
    log.info log_msg
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

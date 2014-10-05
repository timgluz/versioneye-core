require 'benchmark'
require 'dalli'

class GitRepoImportWorker < Worker

  A_TASK_TTL = 180 # 180 seconds = 3 minutes

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("git_repo_import", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        handle body
        cache.set( body, GitHubService::A_TASK_DONE, A_TASK_TTL )

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  private


    def handle message
      sps = message.split(":::")
      provider = sps[0]
      user_id = sps[1]
      repo_id = sps[2]
      user = User.find user_id

      if provider.eql?("stash")
        update_stash_repo( user, repo_id )
      elsif provider.eql?("github")
        update_github_repo( user, repo_id )
      elsif provider.eql?("bitbucket")
        update_bitbucket_repo( user, repo_id )
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


    def update_stash_repo user, repo_id
      repo = StashRepo.find repo_id
      time = Benchmark.measure do
        StashService.update_branches(user, repo)
        StashService.update_project_files(user, repo)
        repo.user_id = user.id
        repo.save
      end
      name = repo[:fullname]

      log_msg = "Reading Stash / `#{name}` took: #{time}"
      puts log_msg
      log.info log_msg
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


    def update_bitbucket_repo user, repo_id
      repo = BitbucketRepo.find repo_id
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


    def update_github_repo user, repo_id
      repo = GithubRepo.find repo_id
      time = Benchmark.measure do
        repo = Github.update_branches      repo, user.github_token
        repo = Github.update_project_files repo, user.github_token
        repo.user_id = user.id
        repo.user_login = user.github_login
        repo.save
      end
      name = repo[:full_name]
      name = repo[:fullname] if name.to_s.empty?

      log_msg = "Reading GitHub / `#{name}` took: #{time}"
      puts log_msg
      log.info log_msg
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end

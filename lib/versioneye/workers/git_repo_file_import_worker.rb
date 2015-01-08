require 'benchmark'
require 'dalli'

class GitRepoFileImportWorker < Worker

  A_TASK_TTL = 60 # 60 seconds = 1 minutes

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("git_repo_file_import", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        import body

        msg = " - job done for #{body}"
        puts msg
        log.info msg

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  private


    def import message
      reload_settings()
      sps = message.split(":::")
      provider  = sps[0]
      username  = sps[1]
      repo_name = sps[2]
      filename  = sps[3]
      branch    = sps[4]
      
      user = User.find_by_username username

      project = nil 
      if provider.eql?("stash")
        project = ProjectImportService.import_from_stash_multi user, repo_name, filename, branch
      elsif provider.eql?("github")
        project = ProjectImportService.import_from_github_multi user, repo_name, filename, branch
      elsif provider.eql?("bitbucket")
        project = ProjectImportService.import_from_bitbucket_multi user, repo_name, filename, branch
      end
      
      if project 
        cache.set( message, "done_#{project.id.to_s}", A_TASK_TTL )
      end 
    rescue => e
      cache.set( message, "error_#{e.message}", A_TASK_TTL )
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end

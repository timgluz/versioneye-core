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
      parent_id = sps[5]
      
      user = User.find_by_username username
      if user.nil? 
        cache.set( message, "error_User `#{username}` not found!", A_TASK_TTL )
        return 
      end

      project = nil 
      if provider.eql?("stash")
        project = ProjectImportService.import_from_stash_multi user, repo_name, filename, branch
      elsif provider.eql?("github")
        project = ProjectImportService.import_from_github_multi user, repo_name, filename, branch
      elsif provider.eql?("github_child")
        parent = Project.find parent_id
        project = ProjectImportService.import_child_from_github user, repo_name, filename, branch, parent
      elsif provider.eql?("bitbucket")
        project = ProjectImportService.import_from_bitbucket_multi user, repo_name, filename, branch
      elsif provider.eql?("bitbucket_child")
        parent = Project.find parent_id
        project = ProjectImportService.import_child_from_bitbucket user, repo_name, filename, branch, parent
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

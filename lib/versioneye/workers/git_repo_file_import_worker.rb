require 'benchmark'
require 'dalli'

class GitRepoFileImportWorker < Worker

  A_TASK_TTL = 60 # 60 seconds = 1 minute

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("git_repo_file_import", :durable => true)

    multi_log " [*] GitRepoFileImportWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] GitRepoFileImportWorker received #{body}"
        import body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] GitRepoFileImportWorker job done #{body}"
      end
    rescue => e
      log.error "ERROR in GitRepoFileImportWorker: #{e.message}"
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
      orga_id   = sps[5]
      multi_log "   [x] GitRepoFileImportWorker import for provider: #{provider}, username: #{username}, repo_name: #{repo_name}, filename: #{filename}, branch: #{branch}, orga: #{orga_id}"

      user = User.find_by_username username
      if user.nil?
        cache.set( message, "error_User `#{username}` not found!", A_TASK_TTL )
        multi_log "   [x] GitRepoFileImportWorker username #{username} not found! Cancel this Job!"
        return
      end

      project = Project.where(:scm_fullname => repo_name, :scm_branch => branch, :s3_filename => filename, :organisation_id => orga_id ).first
      if project.nil?
        if provider.eql?("stash")
          project = ProjectImportService.import_from_stash user, repo_name, filename, branch, orga_id
        elsif provider.eql?("github")
          project = ProjectImportService.import_from_github user, repo_name, filename, branch, orga_id
        elsif provider.eql?("bitbucket")
          project = ProjectImportService.import_from_bitbucket user, repo_name, filename, branch, orga_id
        end
      end

      if project && project.is_a?(Project)
        cache.set( message, "done_#{project.id.to_s}", A_TASK_TTL )
      elsif project && project.is_a?(String)
        cache.set( message, "error_#{project}", A_TASK_TTL )
      else
        cache.set( message, "error_Unknown_ERROR", A_TASK_TTL )
      end
    rescue => e
      cache.set( message, "error_#{e.message}", A_TASK_TTL )
      log.error "ERROR in GitRepoFileImportWorker! Input: #{message} Output: #{e.message}"
      log.error e.backtrace.join("\n")
    end


end

class GitRepoFileImportProducer < Producer


  def initialize msg
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue("git_repo_file_import", :durable => true)

    queue.publish(msg, :persistent => true)

    log_msg = " [x] GitRepoFileImportProducer sent #{msg}"
    puts log_msg
    log.info log_msg

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

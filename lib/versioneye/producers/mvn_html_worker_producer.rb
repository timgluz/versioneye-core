class MvnHtmlWorkerProducer < Producer

  # "central::http://repo.maven.apache.org/maven2/com/versioneye/versioneye-maven-plugin/3.9.0/versioneye-maven-plugin-3.9.0.pom"
  def initialize msg
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue("html_worker", :durable => true)

    queue.publish(msg, :persistent => true)

    log_msg = " [x] MvnHtmlWorkerProducer sent #{msg}"
    puts log_msg
    log.info log_msg

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

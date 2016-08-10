class MvnIndexWorkerProducer < Producer

  # "central::http://repo.maven.apache.org/maven2::g:a:pom:v::published_date"
  # "central::http://repo.maven.apache.org/maven2::com.versioneye:versioneye-maven-plugin:pom:3.9.2::"
  def initialize msg
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue("maven_index_worker", :durable => true)

    queue.publish(msg, :persistent => true)

    log_msg = " [x] MvnIndexWorkerProducer sent #{msg}"
    puts log_msg
    log.info log_msg

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

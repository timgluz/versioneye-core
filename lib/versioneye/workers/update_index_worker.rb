calss UpdateIndexWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("update_index", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        update_index msg

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def update_index msg
    EsProduct.index_newest if msg.eql?("product")
    EsUser.reindex_all if msg.eql?("user")
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

class UpdateMetaDataWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("update_meta_data", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        update_meta_data msg

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def update_meta_data msg
    ProductService.update_meta_data_global
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

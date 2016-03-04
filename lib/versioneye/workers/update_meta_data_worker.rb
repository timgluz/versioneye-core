class UpdateMetaDataWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("update_meta_data", :durable => true)

    multi_log " [*] UpdateMetaDataWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] UpdateMetaDataWorker received #{body}"
        update_meta_data body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] UpdateMetaDataWorker job done #{body}"
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

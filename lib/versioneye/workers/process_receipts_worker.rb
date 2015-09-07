class ProcessReceiptsWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("process_receipts", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        process_receipts

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process_receipts
    ReceiptService.process_receipts
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

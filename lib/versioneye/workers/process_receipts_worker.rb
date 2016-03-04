class ProcessReceiptsWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("process_receipts", :durable => true)

    multi_log " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] ProcessReceiptsWorker received #{body}"
        process_receipts
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] ProcessReceiptsWorker job done #{body}"
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

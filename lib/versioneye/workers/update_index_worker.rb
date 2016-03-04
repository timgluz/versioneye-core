class UpdateIndexWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("update_index", :durable => true)

    multi_log " [*] UpdateIndexWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] UpdateIndexWorker received #{body}"
        update_index body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] UpdateIndexWorker job done #{body}"
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

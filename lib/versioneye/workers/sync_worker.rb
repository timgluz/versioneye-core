class SyncWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("sync_db", :durable => true)

    multi_log " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, message|
        multi_log " [x] SyncWorker Received #{message}"

        process_work message

        multi_log " [x] SyncWorker Job done for #{message}"
        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process_work message
    return nil if message.to_s.empty?

    if message.match(/\Aproject\:\:/)
      project_id = message.split("::")[1]
      project = Project.find project_id
      SyncService.sync_project project
    elsif message.match(/\Aall_products/)
      SyncService.sync_all_products
    end
  end

end

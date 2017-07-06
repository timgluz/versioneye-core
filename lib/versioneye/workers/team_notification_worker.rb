class TeamNotificationWorker < Worker

# This worker handels the update jobs
# And the single project updates.

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("team_notification", :durable => true)

    multi_log " [*] TeamNotificationWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] TeamNotificationWorker received #{body}"
        process body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] TeamNotificationWorker job done #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process body
    orga = Organisation.find body.to_s
    if orga.nil?
      multi_log " [x] TeamNotificationWorker could not find orga for #{body}"
      return nil
    end

    TeamNotificationService.process_orga orga
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

class SendNotificationEmailsWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("send_notification_emails", :durable => true)

    multi_log " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] SendNotificationEmailsWorker received #{body}"
        send_notification_emails body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] SendNotificationEmailsWorker job done #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end

  def send_notification_emails msg
    NotificationService.send_notifications
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

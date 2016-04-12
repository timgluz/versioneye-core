class NotificationQueueWorker < Worker

  def get_connection
    Bunny.new("amqp://rabbitmq-rw5ix14w.cloudapp.net:5672")
  end

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("notificationQueue", :durable => true)

    multi_log " [*] NotificationQueueWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] NotificationQueueWorker received #{body}"
        process body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] NotificationQueueWorker job done #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process body
    json = JSON.parse(body)
    json = json.deep_symbolize_keys
    log_message json
    
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  private

    def log_message json
      p json[:correlationId]
      p json[:impactedFiles].count
      json[:impactedFiles].each do |files|
        p files[:name]
        p files[:path]
        p files[:sha256]
        p "---"
      end
    end

end

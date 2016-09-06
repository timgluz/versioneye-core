class NotificationQueueProducer < Producer

  def get_connection
    Bunny.new("amqp://rabbitmq-rw5ix14w.cloudapp.net:5672")
  end


  # NotificationQueueProducer.new "{\"correlationId\": \"1234567\", \"vulnerableBlobs\": [\"73c5f45af2d5466fdaa4115b8606f75732191feacb5300756dbd09581dbd89d4\"]}"
  def initialize msg
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue("feedImpactQueue", :durable => true)

    queue.publish(msg, :persistent => true)

    log_msg = " [x] NotificationQueueProducer sent #{msg}"
    puts log_msg
    log.info log_msg

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

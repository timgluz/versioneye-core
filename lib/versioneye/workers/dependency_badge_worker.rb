require 'benchmark'
require 'dalli'

class DependencyBadgeWorker < Worker

  A_TTL = 86400 # 24 hours 

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("dependency_badge", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        msg = " [x] Received #{body}"
        puts msg
        log.info msg

        calculate_badge body

        msg = " - job done for #{body}"
        puts msg
        log.info msg

        channel.ack(delivery_info.delivery_tag)
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  private


    def calculate_badge message
      BadgeService.update message
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end

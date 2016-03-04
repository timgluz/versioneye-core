require 'benchmark'
require 'dalli'

class DependencyBadgeWorker < Worker

  A_TTL = 86400 # 24 hours

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("dependency_badge", :durable => true)

    multi_log " [*] DependencyBadgeWorker waiting for messages in #{queue.name}. To exit press CTRL+C"
    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] DependencyBadgeWorker received #{body}"
        calculate_badge body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] DependencyBadgeWorker job done #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  private


    def calculate_badge message
      if message.to_s.match(/ref\z/)
        BadgeRefService.update message
      else
        BadgeService.update message
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end

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
      queue.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
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
      sps = message.split(":::")
      language  = sps[0]
      prod_key  = sps[1]
      version   = sps[2]

      key = "#{language}_#{prod_key}_#{version}"

      product = Product.fetch_product language, prod_key
      product.version = version if !version.to_s.empty?
      dependencies    = product.dependencies

      outdated = DependencyService.dependencies_outdated?( dependencies, false )

      badge = 'out-of-date' if outdated == true
      badge = 'up-to-date'  if outdated == false
      cache.set( key, badge, A_TTL )
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end

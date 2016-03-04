class LanguageDailyStatsWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("language_daily_stats", :durable => true)

    multi_log " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] LanguageDailyStatsWorker received #{body}"
        update_counts
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] LanguageDailyStatsWorker job done for #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def update_counts
    LanguageDailyStats.update_counts(3, 1)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

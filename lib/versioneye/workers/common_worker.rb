class CommonWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    queue   = channel.queue("common_purpose", :durable => true)

    log_msg = " [*] Waiting for messages in #{queue.name}. To exit press CTRL+C"
    puts log_msg
    log.info log_msg

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, message|
        puts " [x] Received #{message}"

        process_work message

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

    if message.eql?("create_indexes")
      Indexer.create_indexes
    elsif message.eql?("update_integration_statuses")
      SubmittedUrlService.update_integration_statuses()
    elsif message.eql?("update_user_languages")
      UserService.update_languages
    elsif message.eql?("update_statistic_data")
      StatisticService.update_all
    elsif message.eql?("send_verification_reminders")
      User.send_verification_reminders
    elsif message.eql?("process_receipts")
      ReceiptService.process_receipts
    elsif message.eql?("update_smc_meta_data_all")
      ScmMetaDataService.update_all_users
    elsif message.eql?("update_distinct_languages")
      LanguageService.update_distinct_languages
    end

    log.info "Job done for #{message}"
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

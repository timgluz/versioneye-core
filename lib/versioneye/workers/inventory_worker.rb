class InventoryWorker < Worker


  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("inventory", :durable => true)

    multi_log " [*] InventoryWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] InventoryWorker received #{body}"
        process body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] InventoryWorker job done #{body}"
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      connection.close
    end
  end


  def process body
    json = JSON.parse(body, {symbolize_names: true})
    if json[:type].to_s.eql?('diff')
      OrganisationService.inventory_diff json[:orga_name], json[:filter1], json[:filter2], json[:diff_id], false
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end

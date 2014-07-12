class GithubRepoImportProducer

  require 'bunny'

  def initialize msg
    connection = Bunny.new("amqp://#{Settings.instance.rabbitmq_addr}:#{Settings.instance.rabbitmq_port}")
    connection.start

    channel = connection.create_channel
    queue   = channel.queue("github_repo_import", :durable => true)

    queue.publish(msg, :persistent => true)
    puts " [x] Sent #{msg}"

    connection.close
  rescue => e
    p e.message
  end

end

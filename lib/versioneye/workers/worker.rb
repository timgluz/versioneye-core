class Worker

  require 'bunny'

  def get_connection
    Bunny.new("amqp://#{Settings.instance.rabbitmq_addr}:#{Settings.instance.rabbitmq_port}")
  end

  def self.log
    if !defined?(@@dynLog) || @@dynLog.nil?
      @@dynLog = Versioneye::DynLog.new("log/worker.log", 10).log
    end
    @@dynLog
  end

  def log
    Worker.log
  end

  def logger
    Worker.log
  end

  def self.cache
    Versioneye::Cache.instance.mc
  end

  def cache
    Versioneye::Cache.instance.mc
  end

  def multi_log msg
    puts msg
    log.info msg
  end

  private

    def reload_settings
      Settings.instance.reload_from_db GlobalSetting.new
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end

end

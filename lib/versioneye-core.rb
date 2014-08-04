require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'tire'
require 'dalli'
require 'httparty'
require 'action_mailer'
require 'stripe'

require 'settings'
require 'versioneye/model'
require 'versioneye/service'

class VersioneyeCore

  def initialize
    puts "start initialize versioneye-core"
    init_logger
    init_mongodb
    init_settings
    init_elastic_search
    init_memcached
    init_email
    init_stripe
    init_s3
    puts "end initialize versioneye-core"
  end

  def init_mongodb
    puts " - initialize MongoDB for #{Settings.instance.environment} "
    Mongoid.load!("config/mongoid.yml", Settings.instance.environment)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def init_email
    puts " - initialize email settings"
    ActionMailer::Base.raise_delivery_errors = true
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.view_paths = File.expand_path('../versioneye/views/', __FILE__)
    EmailSettingService.update_action_mailer_from_db
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def init_stripe
    puts " - initialize Stripe"
    Stripe.api_key = Settings.instance.stripe_secret_key
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def init_s3
    puts " - initialize Amazon S3"
    S3.set_aws_crendentials
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def init_logger
    puts " - initialize Logger"
    Log4r::Configurator.load_xml_file('config/log4r.xml')
  end

  def init_elastic_search
    puts " - initialize ElasticSearch"
    es_url = 'localhost:9200'
    if !Settings.instance.elasticsearch_addr.to_s.empty? && !Settings.instance.elasticsearch_port.to_s.empty?
      es_url = "#{Settings.instance.elasticsearch_addr}:#{Settings.instance.elasticsearch_port}"
    end
    Tire.configure do
      url es_url
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def init_settings
    puts " - reload Settings from DB!"
    Settings.instance.reload_from_db GlobalSetting.new
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def init_memcached
    puts " - initialize init_memcached!"
    Versioneye::Cache.instance.mc
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  private

    def log
      Versioneye::Log.instance.log
    end

end

require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'tire'
require 'dalli'
require 'httparty'
require 'action_mailer'
# require 'will_paginate'

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
    puts "end initialize versioneye-core"
  end

  def init_mongodb
    puts " - initialize MongoDB for #{Settings.instance.environment} "
    Mongoid.load!("config/mongoid.yml", Settings.instance.environment)
  end

  def init_email
    puts " - initialize email settings"
    ActionMailer::Base.raise_delivery_errors = true
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
       :address        => Settings.instance.smtp_address,
       :port           => Settings.instance.smtp_port,
       :domain         => 'versioneye.com',
       :authentication => :plain,
       :user_name      => Settings.instance.smtp_username,
       :password       => Settings.instance.smtp_password,
       :enable_starttls_auto => true
      }
    ActionMailer::Base.view_paths = File.expand_path('../versioneye/views/', __FILE__)
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
  end

  def init_settings
    puts " - reload Settings from DB!"
    Settings.instance.reload_from_db GlobalSetting.new
  end

  def init_memcached
    puts " - initialize init_memcached!"
    Versioneye::Cache.instance.mc
  end

end

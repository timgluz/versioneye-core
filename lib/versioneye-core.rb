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
    puts "initialize versioneye-core"
    init_logger
    init_mongodb
    init_elastic_search
    init_email
  end

  def init_mongodb
    Mongoid.load!("config/mongoid.yml", Settings.instance.environment)
  end

  def init_email
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
    Log4r::Configurator.load_xml_file('config/log4r.xml')
  end

  def init_elastic_search
    Tire.configure do
      url Settings.instance.elasticsearch_url
    end
  end

end

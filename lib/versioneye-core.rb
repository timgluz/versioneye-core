require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'tire'
require 'dalli'
require 'httparty'
require 'action_mailer'

require 'settings'
require 'versioneye/model'
require 'versioneye/service'

class VersioneyeCore

  def initialize
    puts "initialize versioneye-core"
    init_logger
    init_elastic_search

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
    ActionMailer::Base.view_paths = File.expand_path('./versioneye/views/', __FILE__)
  end

  def init_logger
    Configurator.load_xml_file('config/log4r.xml')
  end

  def init_elastic_search
    Tire.configure do
      url Settings.instance.elasticsearch_url
    end
  end

end

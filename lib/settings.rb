require 'singleton'
require 'json'

class Settings
  include Singleton

  def initialize
    puts 'initialize Settings'
    load_settings
  end

  def load_settings( path_to_settings = 'config/settings.json' )
    puts "load #{path_to_settings}"
    json = File.read( path_to_settings )
    settings = JSON.parse(json)
    return nil if settings.nil?

    environment = ENV['RAILS_ENV']
    if environment.to_s == ''
      environment = 'development'
    end
    instance_variable_set("@environment", environment)
    self.class.class_eval { attr_reader "environment".intern }

    settings[environment].each { |name, value|
      if value && value.is_a?(String) && value.match(/^env_/)
        new_val = value.gsub("env_", "")
        if name.eql?("memcache_servers")
          value = eval ENV[new_val]
        else
          value = ENV[new_val]
        end
      end
      instance_variable_set("@#{name}", value)
      self.class.class_eval { attr_reader name.intern }

      if name.eql?("smtp_sender_email") || name.eql?("smtp_sender_name") ||
        name.eql?("server_url") || name.eql?("server_host") || name.eql?("server_port") ||
        name.eql?("github_api_url") || name.eql?("github_client_id") || name.eql?("github_client_secret") ||
        name.eql?("nexus_url")
        self.class.class_eval { attr_writer name.intern }
      end
    }
  end

end

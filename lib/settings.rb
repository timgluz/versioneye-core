require 'singleton'
require 'json'
require 'versioneye/models/global_setting'

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
    if environment.to_s.empty?
      environment = 'development'
    end

    instance_variable_set("@environment", environment)
    self.class.class_eval { attr_reader "environment".intern }

    settings[environment].each { |name, value|
      if value && value.is_a?(String) && value.match(/\Aenv_/)
        new_val = value.gsub("env_", "")
        value = ENV[new_val]
      end

      db_val = load_from_db environment, name
      if !db_val.to_s.empty?
        value = db_val
      end

      instance_variable_set("@#{name}", value)
      self.class.class_eval { attr_reader name.intern }
      self.class.class_eval { attr_writer name.intern }
    }
  end

  def load_from_db env, key
    GlobalSetting.get env, key
  rescue => e
    p e.message
  end

end

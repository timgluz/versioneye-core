require 'singleton'
require 'json'
require 'versioneye/model'
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
    self.class.class_eval { attr_writer "environment".intern } # This is for testing!

    settings[environment].each { |name, value|
      if value && value.is_a?(String) && value.match(/\Aenv_/)
        new_val = value.gsub("env_", "")
        value = ENV[new_val]
      end

      instance_variable_set("@#{name}", value)
      self.class.class_eval { attr_reader name.intern }
      self.class.class_eval { attr_writer name.intern }
    }
  end

  def reload_from_db gs
    return nil if gs.nil?

    keys = gs.keys self.environment
    return nil if keys.nil? || keys.empty?

    keys.each do |key|
      value = gs.get self.environment, key
      value = true  if value.eql?("true")
      value = false if value.eql?("false")
      name = key.downcase
      instance_variable_set("@#{name}", value)
      self.class.class_eval { attr_reader name.intern }
      puts "set #{key.downcase} = #{value}"
    end
  rescue => e
    p e.message
    p e.backtrace.join("\n")
    nil
  end

end

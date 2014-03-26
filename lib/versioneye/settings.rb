require 'singleton'

class Settings
  include Singleton

  json = File.read("config/settings.json")
  settings = JSON.parse(json)
  return nil if settings.nil?

  environment = ENV['RAILS_ENV']
  if environment.to_s == ''
    environment = 'development'
  end

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
  }
end

require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'tire'
require 'dalli'
require 'httparty'

require 'settings'
require 'versioneye/model'
require 'versioneye/service'

class VersioneyeCore

  def initialize
    puts "initialize versioneye-core"
    init_logger
    init_elastic_search
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

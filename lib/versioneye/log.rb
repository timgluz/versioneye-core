require 'singleton'
require 'log4r'
require 'log4r/configurator'

module Versioneye
  class Log
    include Singleton
    include Log4r

    def initialize
      Configurator.load_xml_file('config/log4r.xml')
    end

    def log
      Logger['MainLogger']
    end

  end
end

require 'log4r'
require 'log4r/configurator'
require 'mongoid'
require 'dalli'
require 'httparty'

require 'settings'
require 'versioneye/model'
require 'versioneye/service'

class VersioneyeCore

  def initialize
    puts "init"
  end

  def self.servus
    puts "Ja Servus!"
  end

end

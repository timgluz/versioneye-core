require 'singleton'

module Versioneye
  class Cache
    include Singleton

    def initialize
      mc_url = '127.0.0.1:11211'
      if !Settings.instance.memcache_addr.to_s.empty? && !Settings.instance.memcache_port.to_s.empty?
        mc_url = "#{Settings.instance.memcache_addr}:#{Settings.instance.memcache_port}"
      end
      options = { :username => '', :password => '', :namespace => 'veye', :expires_in => 1.day, :compress => true }
      @memcache = Dalli::Client.new( mc_url, options )
    end

    def mc
      @memcache
    end

  end
end

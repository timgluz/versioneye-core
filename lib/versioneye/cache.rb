require 'singleton'

module Versioneye
  class Cache
    include Singleton

    def initialize
      options = { :username => '', :password => '', :namespace => 'veye', :expires_in => 1.day, :compress => true }
      @memcache = Dalli::Client.new('127.0.0.1:11211')
    end

    def mc
      @memcache
    end

  end

end

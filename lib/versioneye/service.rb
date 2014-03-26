module Versioneye
  class Service

    require 'log4r'
    require 'log4r/configurator'

    include Log4r

    Configurator.load_xml_file('config/log4r.xml')

    def self.log
      Logger['MainLogger']
    end


    require 'dalli'

    def self.cache
      options = { :username => '', :password => '', :namespace => 'veye', :expires_in => 1.day, :compress => true }
      Dalli::Client.new('127.0.0.1:11211')
    end


    require 'versioneye/services/analytics_service'
    require 'versioneye/services/bitbucket_service'
    require 'versioneye/services/circle_element_service'
    require 'versioneye/services/dependency_service'
    require 'versioneye/services/git_hub_service'
    require 'versioneye/services/product_service'
    require 'versioneye/services/project_service'
    require 'versioneye/services/projectdependency_service'
    require 'versioneye/services/statistic_service'
    require 'versioneye/services/user_service'
    require 'versioneye/services/version_service'

    require 'versioneye/services_ext/bitbucket'
    require 'versioneye/services_ext/es_product'
    require 'versioneye/services_ext/es_user'
    require 'versioneye/services_ext/github'
    require 'versioneye/services_ext/mongo_product'
    require 'versioneye/services_ext/octokit_api'
    require 'versioneye/services_ext/s3'
    require 'versioneye/services_ext/stripe_service'

  end
end

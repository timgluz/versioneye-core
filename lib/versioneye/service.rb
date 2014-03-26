module Versioneye
  class Service

    include Log4r

    Configurator.load_xml_file('config/log4r.xml')

    def self.log
      Logger['MainLogger']
    end

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

    require 'versioneye/parsers/bower_parser'
    require 'versioneye/parsers/common_parser'
    require 'versioneye/parsers/composer_lock_parser'
    require 'versioneye/parsers/composer_parser'
    require 'versioneye/parsers/gemfile_parser'
    require 'versioneye/parsers/gemfilelock_parser'
    require 'versioneye/parsers/gradle_parser'
    require 'versioneye/parsers/lein_parser'
    require 'versioneye/parsers/package_parser'
    require 'versioneye/parsers/parser_strategy'
    require 'versioneye/parsers/podfile_parser'
    require 'versioneye/parsers/podfilelock_parser'
    require 'versioneye/parsers/pom_json_parser'
    require 'versioneye/parsers/pom_parser'
    require 'versioneye/parsers/python_setup_parser'
    require 'versioneye/parsers/requirements_parser'

  end
end

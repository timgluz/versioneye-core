# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

# require 'simplecov'
require 'versioneye-core'
require 'rspec/autorun'
require 'mongoid'
require 'database_cleaner'
require 'rubygems'
require 'bundler'
require 'shoulda'
require 'factory_girl'

require 'versioneye/domain_factories/api_factory'
require 'versioneye/domain_factories/dependency_factory'
require 'versioneye/domain_factories/notification_factory'
require 'versioneye/domain_factories/product_factory'
require 'versioneye/domain_factories/product_resource_factory'
require 'versioneye/domain_factories/project_factory'
require 'versioneye/domain_factories/projectdependency_factory'
require 'versioneye/domain_factories/stripe_invoice_factory'
require 'versioneye/domain_factories/submitted_url_factory'
require 'versioneye/domain_factories/user_factory'

require 'versioneye/factories/dependency_factory'
require 'versioneye/factories/github_repo_factory'
require 'versioneye/factories/license_factory'
require 'versioneye/factories/newest_factory'
require 'versioneye/factories/product_factory'
require 'versioneye/factories/project_dependency_factory'
require 'versioneye/factories/project_factory'
require 'versioneye/factories/user_factory'
require 'versioneye/factories/version_factory'

Mongoid.load!("config/mongoid.yml", :test)
Mongoid.logger.level = Logger::ERROR
Moped.logger.level   = Logger::ERROR

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  #include FactoryGirl into test DSL
  config.include FactoryGirl::Syntax::Methods

end

# module SimpleCov::Configuration
#   def clean_filters
#     @filters = []
#   end
# end

# SimpleCov.configure do
#   clean_filters
#   load_adapter 'test_frameworks'
# end

# ENV["COVERAGE"] && SimpleCov.start do
#   add_filter "/.rvm/"
# end

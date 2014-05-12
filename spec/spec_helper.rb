# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start do
  add_filter "/spec"
end

require 'versioneye-core'
require 'rspec/autorun'
require 'mongoid'
require 'database_cleaner'
require 'rubygems'
require 'bundler'
require 'factory_girl'

require 'vcr'
require 'webmock/rspec'
require 'fakeweb'

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
require 'versioneye/domain_factories/license_factory'

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

  AWS.config(:s3_endpoint => 'localhost', :s3_port => 4567, :use_ssl => false )

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.clean
    FakeWeb.clean_registry
  end

  #include FactoryGirl into test DSL
  config.include FactoryGirl::Syntax::Methods

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
    c.ignore_localhost = true
    c.hook_into :webmock # or :fakeweb
    c.allow_http_connections_when_no_cassette = true
  end

  ActionMailer::Base.view_paths = File.expand_path('../../lib/versioneye/views/', __FILE__)
  ActionMailer::Base.delivery_method = :test

end

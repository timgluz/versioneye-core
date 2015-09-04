# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start do
  add_filter "/spec"
end

require 'rack/test'
require 'stripe'
require 'versioneye-core'
require 'mongoid'
require 'database_cleaner'
require 'rubygems'
require 'bundler'
require 'factory_girl'
require 'will_paginate_mongoid'

require 'vcr'
require 'webmock'
require 'fakeweb'

require 'versioneye/mocks/ldap_mock'

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
require 'versioneye/domain_factories/billing_address_factory'
require 'versioneye/domain_factories/stripe_factory'
require 'versioneye/domain_factories/receipt_factory'
require 'versioneye/domain_factories/license_whitelist_factory'

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

  VersioneyeCore.new

  if (!Settings.instance.environment.eql?('test'))
    p "---"
    p "*** YOU ARE NOT IN A TEST ENVIRONMENT! ***"
    p "---"
    return nil
  end

  Stripe.api_key = Settings.instance.stripe_secret_key

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

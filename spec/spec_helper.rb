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

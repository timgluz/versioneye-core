source "http://rubygems.org"

# Specify your gem's dependencies in versioneye-core.gemspec
gemspec

# 20% performance boost for dalli. Doesn't work on Windows.
gem 'kgio', '~> 2.11.0', platforms: :ruby

group :test do
  gem 'rack-test'       , '0.6.3'
  gem 'fakes3'          , '0.2.4'
  gem 'simplecov'       , '~> 0.14.1'
  gem 'rspec'           , '~> 3.5.0'
  gem 'rspec_junit_formatter', '0.2.3'
  gem 'database_cleaner', '~> 1.5.1'
  gem 'factory_girl'    , '~> 4.8.0'
  gem 'capybara'        , '~> 2.13.0'
  gem 'capybara-firebug', '~> 2.1.0'
  gem 'vcr'             , '3.0.3', :require => false
  gem 'webmock'         , '~> 2.1.0', :require => false
  gem 'fakeweb'         , '~> 1.3.0'
end

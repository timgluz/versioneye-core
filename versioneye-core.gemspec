$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'versioneye/version'

Gem::Specification.new do |s|
  s.name             = "versioneye-core"
  s.version          = Versioneye::VERSION
  s.require_paths    = ["lib"]
  s.authors          = ['Robert Reiz']
  s.email            = "robert.reiz.81@gmail.com"
  s.homepage         = "http://github.com/versioneye/versioneye-core"
  s.license          = "MIT"
  s.summary          = "Models & Services for VersionEye"
  s.description      = "This project contains the Models and Services for VersionEye"
  s.extra_rdoc_files = ['LICENSE.txt', 'README.md']
  s.files            = `git ls-files -z`.split("\0")

  s.add_runtime_dependency 'bundler', '~> 1.12.5'
  s.add_runtime_dependency 'naturalsorter', '~> 3.0.14'
  s.add_runtime_dependency 'dalli', '~> 2.7.0'
  s.add_runtime_dependency 'oauth', '~> 0.5.0'
  s.add_runtime_dependency 'aws-sdk', '~> 2.3.0'
  s.add_runtime_dependency 'stripe', '~> 1.48.0'
  s.add_runtime_dependency 'tire', '~> 0.6.2'
  s.add_runtime_dependency 'octokit', '~> 4.3.0'
  s.add_runtime_dependency 'semverly', '~> 1.0.0'
  s.add_runtime_dependency 'httparty', '~> 0.13.1'
  s.add_runtime_dependency 'persistent_httparty', '~> 0.1.0'
  s.add_runtime_dependency 'nokogiri', '~> 1.6.8'
  s.add_runtime_dependency 'cocoapods-core', '~> 0.39.0'
  s.add_runtime_dependency 'actionmailer', '~> 4.2.6'
  s.add_runtime_dependency 'pdfkit', '~> 0.8.0'
  s.add_runtime_dependency 'bunny', '~> 2.4.0'
  s.add_runtime_dependency 'wkhtmltopdf-binary', '~> 0.9.9.1'
  s.add_runtime_dependency 'etcd', '~> 0.3.0'
  s.add_runtime_dependency 'mongoid', '~> 5.1.0'
  s.add_runtime_dependency 'will_paginate_mongoid', '= 2.0.1'
  s.add_runtime_dependency 'net-ldap', '~> 0.14.0'
end

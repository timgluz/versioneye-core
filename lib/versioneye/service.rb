module Versioneye
  class Service

    require 'versioneye/log'
    require 'versioneye/cache'

    require 'versioneye/services/analytics_service'
    require 'versioneye/services/bitbucket_service'
    require 'versioneye/services/circle_element_service'
    require 'versioneye/services/dependency_service'
    require 'versioneye/services/git_hub_service'
    require 'versioneye/services/http_service'
    require 'versioneye/services/notification_service'
    require 'versioneye/services/newsletter_service'
    require 'versioneye/services/product_service'
    require 'versioneye/services/project_service'
    require 'versioneye/services/project_import_service'
    require 'versioneye/services/project_update_service'
    require 'versioneye/services/project_parse_service'
    require 'versioneye/services/projectdependency_service'
    require 'versioneye/services/receipt_service'
    require 'versioneye/services/statistic_service'
    require 'versioneye/services/submitted_url_service'
    require 'versioneye/services/user_service'
    require 'versioneye/services/admin_service'
    require 'versioneye/services/version_service'
    require 'versioneye/services/email_setting_service'
    require 'versioneye/services/reference_service'
    require 'versioneye/services/language_service'
    require 'versioneye/services/license_service'

    require 'versioneye/services_ext/bitbucket'
    require 'versioneye/services_ext/es_product'
    require 'versioneye/services_ext/es_user'
    require 'versioneye/services_ext/github'
    require 'versioneye/services_ext/mongo_product'
    require 'versioneye/services_ext/octokit_api'
    require 'versioneye/services_ext/s3'
    require 'versioneye/services_ext/stripe_service'

    require 'versioneye/mailers/notification_mailer'
    require 'versioneye/mailers/feedback_mailer'
    require 'versioneye/mailers/newsletter_mailer'
    require 'versioneye/mailers/project_mailer'
    require 'versioneye/mailers/submitted_url_mailer'
    require 'versioneye/mailers/subscription_mailer'
    require 'versioneye/mailers/user_mailer'
    require 'versioneye/mailers/receipt_mailer'
    require 'versioneye/mailers/versioncomment_mailer'
    require 'versioneye/mailers/versioncommentreply_mailer'

    require 'versioneye/parsers/bower_parser'
    require 'versioneye/parsers/common_parser'
    require 'versioneye/parsers/composer_lock_parser'
    require 'versioneye/parsers/composer_parser'
    require 'versioneye/parsers/gemfile_parser'
    require 'versioneye/parsers/gemfilelock_parser'
    require 'versioneye/parsers/gradle_parser'
    require 'versioneye/parsers/sbt_parser'
    require 'versioneye/parsers/lein_parser'
    require 'versioneye/parsers/package_parser'
    require 'versioneye/parsers/parser_strategy'
    require 'versioneye/parsers/podfile_parser'
    require 'versioneye/parsers/podfilelock_parser'
    require 'versioneye/parsers/pom_json_parser'
    require 'versioneye/parsers/pom_parser'
    require 'versioneye/parsers/python_setup_parser'
    require 'versioneye/parsers/requirements_parser'

    require 'versioneye/updaters/update_strategy'
    require 'versioneye/updaters/common_updater'
    require 'versioneye/updaters/bitbucket_updater'
    require 'versioneye/updaters/github_updater'
    require 'versioneye/updaters/upload_updater'
    require 'versioneye/updaters/url_updater'

    require 'versioneye/producers/producer.rb'
    require 'versioneye/producers/github_repo_import_producer.rb'
    require 'versioneye/producers/github_repos_import_producer.rb'
    require 'versioneye/producers/bitbucket_repos_import_producer.rb'
    require 'versioneye/producers/bitbucket_repo_import_producer.rb'

    require 'versioneye/workers/worker.rb'
    require 'versioneye/workers/github_repo_import_worker.rb'
    require 'versioneye/workers/github_repos_import_worker.rb'
    require 'versioneye/workers/bitbucket_repos_import_worker.rb'
    require 'versioneye/workers/bitbucket_repo_import_worker.rb'

    def self.log
      Versioneye::Log.instance.log
    end

    def log
      Versioneye::Log.instance.log
    end

    def self.cache
      Versioneye::Cache.instance.mc
    end

    def cache
      Versioneye::Cache.instance.mc
    end

  end

end

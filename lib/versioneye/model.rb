module Versioneye
  class Model

    require 'versioneye/log'

    require 'versioneye/models/api_cmp'
    require 'versioneye/models/artefact'
    require 'versioneye/models/pullrequest'
    require 'versioneye/models/pr_issue'
    require 'versioneye/models/mail_track'
    require 'versioneye/models/badge'
    require 'versioneye/models/docker_image'
    require 'versioneye/models/api'
    require 'versioneye/models/api_call'
    require 'versioneye/models/auditlog'
    require 'versioneye/models/billing_address'
    require 'versioneye/models/bitbucket_repo'
    require 'versioneye/models/circle_element'
    require 'versioneye/models/crawle'
    require 'versioneye/models/crawler_task'
    require 'versioneye/models/dependency'
    require 'versioneye/models/developer'
    require 'versioneye/models/author'
    require 'versioneye/models/error_message'
    require 'versioneye/models/event'
    require 'versioneye/models/email_setting'
    require 'versioneye/models/enterprise_lead'
    require 'versioneye/models/github_repo'
    require 'versioneye/models/inventory'
    require 'versioneye/models/inventory_item'
    require 'versioneye/models/stash_repo'
    require 'versioneye/models/scm_changelog_entry'
    require 'versioneye/models/json_cache'
    require 'versioneye/models/language'
    require 'versioneye/models/language_daily_stats'
    require 'versioneye/models/language_feed'
    require 'versioneye/models/component_whitelist'
    require 'versioneye/models/license'
    require 'versioneye/models/license_suggestion'
    require 'versioneye/models/license_whitelist'
    require 'versioneye/models/license_element'
    require 'versioneye/models/license_cach'
    require 'versioneye/models/maven_repository'
    require 'versioneye/models/newest'
    require 'versioneye/models/notification'
    require 'versioneye/models/organisation'
    require 'versioneye/models/team'
    require 'versioneye/models/team_member'
    require 'versioneye/models/pom'
    require 'versioneye/models/plan'
    require 'versioneye/models/product'
    require 'versioneye/models/product_resource'
    require 'versioneye/models/project'
    require 'versioneye/models/projectdependency'
    require 'versioneye/models/refer'
    require 'versioneye/models/receipt'
    require 'versioneye/models/receipt_line'
    require 'versioneye/models/repository'
    require 'versioneye/models/searchlog'
    require 'versioneye/models/security_vulnerability'
    require 'versioneye/models/submitted_url'
    require 'versioneye/models/spdx_license'
    require 'versioneye/models/user'
    require 'versioneye/models/user_email'
    require 'versioneye/models/user_notification_setting'
    require 'versioneye/models/userlinkcollection'
    require 'versioneye/models/user_permission'
    require 'versioneye/models/version'
    require 'versioneye/models/versionarchive'
    require 'versioneye/models/versioncomment'
    require 'versioneye/models/versioncommentreply'
    require 'versioneye/models/versionlink'
    require 'versioneye/models/global_setting'
    require 'versioneye/models/np_domain'
    require 'versioneye/models/reference'
    require 'versioneye/models/sync_status'
    require 'versioneye/models/helpers/indexer'

    def ids
      self.id.to_s
    end

    def self.log
      Versioneye::Log.instance.log
    end

    def log
      Versioneye::Log.instance.log
    end

  end
end

# Monkey patch for MongoID 5 update.
# They removed `remove_all` and here we add it back!
module Mongo
  class Collection
    class View
      def remove_all
        remove(0)
      end
    end
  end
end

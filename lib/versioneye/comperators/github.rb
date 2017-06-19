require 'octokit'

module Comperators
  module Github
    def log
      Versioneye::Log.instance.log
    end


    #TODO: remove it as every pkg-manager have their own versions
    def parse_requested_version_github(version_label, dependency, product = nil)
      if commit_sha?(version_label)
        dependency[:version_requested] = version_label
        dependency[:version_label] = version_label
        comperator[:comperator] = '='
      end
    end


    #checks the state of version label
    def compare_github_version(version_label, dependency, product_versions, auth_token)

      repo_fullname = dependency[:repo_fullname]
      if repo_fullname.nil?
        log.error "compare_github_version: dependency has no :repo_fullname, #{dependency}"
        return IS_UNKNOWN
      end

      commit_dt = fetch_version_commit(repo_fullname, version_label, auth_token)
      if commit_dt.nil? or  commit_dt.has_key?(:committer) == false
        log.error "compare_github_version: got no commit informations for #{repo_fullname}/#{version_label}"
        return IS_UNKNOWN
      end

      latest_version = VersionService.newest_version(product_versions)
      if latest_version.nil?
        log.error "compare_github_version: product has no releases: #{product_versions}"
        return IS_UNKNOWN
      end

      # github release is outdated only iff commit date is older than latest stable release
      # we will ignore any later commit after stable release as they are unstable

      commit_dt = parse_date(commit_dt[:committer][:date]).to_i
      version_dt = latest_version[:released_at].to_i

      if commit_dt == 0 or version_dt == 0
        log.warn "compare_github_version: no dates #{commit_dt} or #{version_dt}"
        IS_UNKNOWN
      elsif commit_dt < version_dt
        IS_OUTDATED
      else
        IS_UPTODATE
      end
    rescue => e
      log.error "compare_github_version: failed to check commit version."
      log.error "\tdetails: dep: #{dependency}, version: #{version_label}"
      log.error e.message.to_s

      IS_UNKNOWN
    end

    #TODO: check Request LIMITS
    #TODO: add cases for tags and branches
    def fetch_version_commit(repo_fullname, version_label, auth_token)
      if commit_sha?(version_label)
        fetch_commit_details(repo_fullname, version_label, auth_token)
      end
    end

    def fetch_commit_details(repo_fullname, commit_sha, auth_token)
      gh = Octokit::Client.new(auth_token: auth_token)
      res = gh.commit(repo_fullname, commit_sha)
      res[:commit]
    rescue
      nil
    end

    # checks if version label is proper commit sha
    # NB! it may give false positives for shorts shas when version label is a datestring
    # for example: 20170616 will be true
    def commit_sha?(version_label)
      lbl = version_label.to_s.strip
      return false if lbl.empty?

      /\A[\d|a-f]{7,40}\b/i.match?(lbl)
    end

    def parse_date(dt_str)
      return dt_str if dt_str.is_a?(DateTime) #octokit parses dates into DateTime
      return dt_str if dt_str.is_a?(Time)

      DateTime.parse dt_str
    rescue => e
      log.error "parse_date: failed to parse date string `#{dt_str}`"
      log.error e.message.to_s
      log.error e.backtrace.join('\n')
      nil
    end

  end
end

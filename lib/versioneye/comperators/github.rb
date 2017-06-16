module Comperators
  module Github
    def parse_requested_version_github(version_label, dependency, product = nil)
      if commit_sha?(version_label)
        dependency[:version_requested] = version_label
        dependency[:version_label] = version_label
        comperator[:comperator] = '='
      end
    end


    #checks the state of version label
    def check_version(version_label, dependency, product_versions, auth_token)
      repo_fullname = dependency[:repo_fullname]
      if repo_fullname.nil?
        return IS_UNKNOWN
      end

      commit_dt = if commit_sha?(dependency)
                    fetch_latest_commit_by_sha(dependency[:repo_fullname], auth_token)
                  end

      return IS_UNKNOWN if commit_dt.nil? == false
    end

    # checks if version label is proper commit sha
    # NB! it may give false positives for shorts shas when version label is a datestring
    # for example: 20170616 will be true
    def commit_sha?(version_label)
      lbl = version_label.to_s.strip
      return false if lbl.empty?

      /\A[\d|a-f]{7,40}\b/i.match?(lbl)
    end
  end
end

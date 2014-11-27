class UpdateStrategy

  def self.updater_for( project_source )
    case project_source
    when Project::A_SOURCE_UPLOAD
      return UploadUpdater.new

    when Project::A_SOURCE_URL
      return UrlUpdater.new

    when Project::A_SOURCE_GITHUB
      return GithubUpdater.new

    when Project::A_SOURCE_BITBUCKET
      return BitbucketUpdater.new

    when Project::A_SOURCE_STASH
      return StashUpdater.new

    when Project::A_SOURCE_API
      return UploadUpdater.new

    else
      return UploadUpdater.new

    end
  end
end

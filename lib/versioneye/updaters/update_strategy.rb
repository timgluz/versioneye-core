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

    when Project::A_SOURCE_API
      return UrlUpdater.new

    else
      return UrlUpdater.new

    end
  end
end

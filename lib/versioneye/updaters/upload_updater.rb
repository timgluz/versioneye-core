class UploadUpdater

  def update( project )
    project.dependencies.each do |dep|
      ProjectdependencyService.outdated?( dep )
    end
    project
  end

end

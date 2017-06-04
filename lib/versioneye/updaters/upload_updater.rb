class UploadUpdater < CommonUpdater

  def update project
    return nil if project.nil?

    out_number = 0
    dep_number = 0
    project.dependencies.each do |dep|
      dep.outdated = nil
      outdated = ProjectdependencyService.outdated?( dep )
      out_number += 1 if outdated
      dep_number += 1
    end
    project.reload

    cache.delete( project.id.to_s ) # Delete badge status for project

    SyncService.sync_project_async project # For Enterprise environment

    ProjectdependencyService.update_licenses_security project

    unknown_licenses = ProjectService.unknown_licenses( project )
    red_licenses     = ProjectService.red_licenses( project )
    project.licenses_red = red_licenses.count
    project.licenses_unknown = unknown_licenses.count
    project.dep_number = dep_number
    project.out_number = out_number
    project.sum_own!
    project.updated_at = Time.now
    project.save
    project
  end

end

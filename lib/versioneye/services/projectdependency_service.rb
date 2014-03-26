class ProjectdependencyService

  require 'naturalsorter'

  A_SECONDS_PER_DAY = 24 * 60 * 60 # 24h * 60min * 60s = 86400

  # TODO refactor the usage of this method.
  # TODO test this

  def self.release?( projectdependency )
    if projectdependency.release.nil?
      projectdependency.release = VersionTagRecognizer.release? projectdependency.version_current
      projectdependency.save
    end
    projectdependency.release
  end


  def self.outdated?( projectdependency )
    return update_outdated!(projectdependency) if projectdependency.outdated.nil?
    last_update_ago = Time.now - projectdependency.outdated_updated_at
    return projectdependency.outdated if last_update_ago < A_SECONDS_PER_DAY
    update_outdated!( projectdependency )
  end


  def self.update_outdated!( projectdependency )
    update_version_current( projectdependency )

    if ( projectdependency.prod_key.nil? && projectdependency.version_current.nil? ) ||
       ( projectdependency.version_requested.eql?( 'GIT' ) || projectdependency.version_requested.eql?('PATH') ) ||
       ( projectdependency.version_requested.eql?( projectdependency.version_current) )
      return update_outdated( projectdependency, false )
    end

    newest_version = Naturalsorter::Sorter.sort_version([projectdependency.version_current, projectdependency.version_requested]).last
    if newest_version.eql?( projectdependency.version_requested)
      return update_outdated( projectdependency, false )
    end

    update_outdated( projectdependency, true )
    projectdependency.outdated
  end


  def self.update_outdated( projectdependency, out_value )
    projectdependency.outdated = out_value
    projectdependency.outdated_updated_at = DateTime.now
    projectdependency.save
    projectdependency.outdated
  rescue => e
    log.error e.message
    log.error e.backtrace.join '\n'
    out_value
  end


  def self.update_version_current( projectdependency )
    return false if projectdependency.prod_key.nil?

    language    = projectdependency.language
    prod_key    = projectdependency.prod_key
    group_id    = projectdependency.group_id
    artifact_id = projectdependency.artifact_id

    product = Product.fetch_product language, prod_key
    if product.nil? && group_id && artifact_id
      product = Product.find_by_group_and_artifact( group_id, artifact_id )
    end
    return false if product.nil?

    newest_version = VersionService.newest_version_number( product.versions, projectdependency.stability )
    return false if newest_version.nil? || newest_version.empty?

    version_current = projectdependency.version_current
    if version_current.nil? || version_current.empty? || !version_current.eql?( newest_version )
      projectdependency.version_current = newest_version
      projectdependency.release         = VersionTagRecognizer.release? projectdependency.version_current
      projectdependency.muted = false
      projectdependency.save()
    end
  end


end

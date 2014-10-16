class ProjectdependencyService < Versioneye::Service

  require 'naturalsorter'

  A_SECONDS_PER_DAY = 24 * 60 * 60 # 24h * 60min * 60s = 86400


  def self.release?( projectdependency )
    return nil if projectdependency.nil? || projectdependency.version_current.nil?

    projectdependency.release = VersionTagRecognizer.release? projectdependency.version_current
    projectdependency.save
    projectdependency.release
  end


  def self.outdated?( projectdependency )
    return nil if projectdependency.nil?

    return update_outdated!(projectdependency) if projectdependency.outdated.nil?

    last_update_ago = DateTime.now.to_i - projectdependency.outdated_updated_at.to_i
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
    outdated = !newest_version.eql?( projectdependency.version_requested)
    update_outdated( projectdependency, outdated )
    projectdependency.outdated
  end


  def self.update_outdated( projectdependency, out_value )
    projectdependency.outdated = out_value
    projectdependency.outdated_updated_at = DateTime.now
    if !projectdependency.version_current.nil?
      self.release? projectdependency
    end
    projectdependency.save
    projectdependency.outdated
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    out_value
  end


  def self.update_version_current( projectdependency )
    return false if projectdependency.prod_key.nil?

    product = projectdependency.find_or_init_product
    return false if product.nil? || product.prod_key.nil?

    newest_version = VersionService.newest_version_number( product.versions, projectdependency.stability )
    return false if newest_version.nil? || newest_version.empty?

    version_current = projectdependency.version_current
    if version_current.nil? || version_current.empty? || !version_current.eql?( newest_version )
      projectdependency.version_current = newest_version
      projectdependency.release = VersionTagRecognizer.release? projectdependency.version_current
      projectdependency.muted = false
      projectdependency.save()
    end
    true
  rescue => e
    log.error e.message
  end


  def self.update_prod_key dependency
    prod_key = dependency.name
    if dependency.group_id && dependency.artifact_id
      prod_key = "#{dependency.group_id}/#{dependency.artifact_id}"
    end
    product = Product.fetch_product dependency.language, prod_key
    return if product.nil?

    dependency.prod_key = prod_key
    dependency.save
    ProjectdependencyService.update_outdated! dependency
  end


  def self.update_prod_keys
    Projectdependency.all.each do |dependency|
      update_prod_key dependency
    end
  end

end

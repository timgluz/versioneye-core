class ProjectdependencyService < Versioneye::Service

  require 'naturalsorter'

  A_SECONDS_PER_DAY = 24 * 60 * 60 # 24h * 60min * 60s = 86400

  # Updates projectdependency.license_caches for each projectdependency of the project
  def self.update_licenses project 
    project.projectdependencies.each do |dep| 
      product = dep.find_or_init_product
      update_licenses_for project, dep, product
    end
  rescue => e 
    log.error e.message
    log.error e.backtrace.join "\n"
  end

  def self.update_licenses_for project, dep, product, save_dep = true 
    dep.license_caches.clear
    dep.lwl_violation = nil 
    product.version = dep.version_requested 
    licenses = product.licenses
    if licenses && !licenses.empty? 
      fill_license_cache project, dep, licenses
    end
    dep.save if save_dep
  end


  # Updates projectdependency.sv_ids for each projectdependency of the project
  def self.update_security project 
    project.update_attribute(:sv_count, 0)
    project.update_attribute(:sv_count_sum, 0)
    project.projectdependencies.each do |dep| 
      product = dep.find_or_init_product
      update_security_for project, dep, product
    end
  rescue => e 
    log.error e.message
    log.error e.backtrace.join "\n"
  end

  def self.update_security_for project, dep, product, save_dep = true    
    version = product.version_by_number dep.version_requested 
    return nil if version.nil? 

    dep.sv_ids = version.sv_ids
    dep.save if save_dep

    if !version.sv_ids.empty?
      new_count = project.sv_count + version.sv_ids.size
      project.update_attribute(:sv_count, new_count)
    end
  end


  def self.update_licenses_security project
    project.update_attribute(:sv_count, 0)
    project.update_attribute(:sv_count_sum, 0)
    Projectdependency.where(:project_id => project.id).each do |dep|
      product = dep.find_or_init_product
      update_licenses_for project, dep, product, false
      update_security_for project, dep, product, false 
      dep.save 
    end
  rescue => e 
    log.error e.message
    log.error e.backtrace.join "\n"  
  end


  def self.mute! project_id, dependency_id, mute_status
    project = Project.find_by_id( project_id )
    return false if project.nil?

    dependency = Projectdependency.find_by_id dependency_id
    return false if dependency.nil?
    return false if !dependency.project_id.to_s.eql? project_id
    return false if dependency.project.nil?

    dependency.muted = mute_status
    if mute_status == true
      dependency.outdated = false
      dependency.outdated_updated_at = DateTime.now
      update_project_numbers dependency, project 
    else
      update_outdated! dependency
      update_project_numbers dependency, project 
    end
    saved = dependency.save
    up = project
    up = project.parent if project.parent_id 
    ProjectService.update_sums up
    ProjectService.reset_badge up 
    saved 
  end


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
       ( projectdependency.muted == true ) ||
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
    if projectdependency.prod_key.nil?
      update_prod_key projectdependency
    end
    
    product = projectdependency.product
    return false if product.nil?

    newest_version = VersionService.newest_version_number( product.versions, projectdependency.stability )
    return false if newest_version.nil? || newest_version.empty?

    version_current = projectdependency.version_current
    if version_current.to_s.empty? || !version_current.eql?( newest_version )
      projectdependency.version_current = newest_version
      projectdependency.release = VersionTagRecognizer.release? projectdependency.version_current
      projectdependency.muted = false
    end
    if projectdependency.version_requested.to_s.empty?
      projectdependency.version_requested = newest_version
    end
    if projectdependency.version_label.to_s.empty?
      projectdependency.version_label = projectdependency.version_requested
    end
    projectdependency.save()
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    false
  end


  def self.update_prod_key dependency
    product = dependency.find_or_init_product
    return nil if product.nil?

    dependency.prod_key = product.prod_key
    dependency.save
  end


  def self.update_prod_keys
    Projectdependency.all.each do |dependency|
      update_prod_key dependency
    end
  end


  private 


    def self.update_project_numbers dependency, project 
      if dependency.outdated 
        project.out_number = project.out_number.to_i + 1 
        project.out_number_sum = project.out_number_sum.to_i + 1 
      else 
        project.out_number = project.out_number.to_i - 1 
        project.out_number_sum = project.out_number_sum.to_i - 1   
      end
      project.out_number = 0 if project.out_number < 0 
      project.out_number_sum = 0 if project.out_number_sum < 0
      project.save 
    end


    def self.fill_license_cache project, dependency, licenses
      licenses.each do |license|
        licenseCach = LicenseCach.new({:name => license.name_substitute, :url => license.link} )
        if project.license_whitelist
          licenseCach.on_whitelist = project.license_whitelist.include_license_substitute?( license.name_substitute )
        end
        licenseCach.license_id = license.id.to_s 
        dependency.license_caches.push licenseCach
        dependency.lwl_violation = 'true' if licenseCach.on_whitelist == false 
        licenseCach.save 
      end
    end


end

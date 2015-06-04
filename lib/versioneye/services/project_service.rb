class ProjectService < Versioneye::Service


  def self.type_by_filename filename
    return nil if filename.to_s.empty?
    return nil if filename.to_s.match(/\/node_modules\//) # Skip workirectory of NPM. 

    trimmed_name = filename.split('?')[0]
    return Project::A_TYPE_RUBYGEMS  if (!(/Gemfile\z/ =~ trimmed_name).nil?)        or (!(/Gemfile.lock\z/  =~ trimmed_name).nil?)
    return Project::A_TYPE_COMPOSER  if (!(/composer.json\z/ =~ trimmed_name).nil?)  or (!(/composer.lock\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_PIP       if (!(/requirements\S*.txt\z/ =~ trimmed_name).nil?)  or (!(/setup.py\z/ =~ trimmed_name).nil?) or (!(/pip.log\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_NPM       if (!(/package.json\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_GRADLE    if (!(/.gradle\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_SBT       if (!(/.sbt\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_MAVEN2    if (!(/pom.xml\z/ =~ trimmed_name).nil?)  or (!(/pom.json\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_LEIN      if (!(/project.clj\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_BOWER     if (!(/bower.json\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_BIICODE   if (!(/biicode.conf\z/ =~ trimmed_name).nil?)
    return Project::A_TYPE_COCOAPODS if (!(/Podfile\z/ =~ trimmed_name).nil?)  or (!(/.podfile\z/ =~ trimmed_name).nil?) or (!(/Podfile.lock\z/ =~ trimmed_name).nil?)
    return nil
  end

  
  def self.corresponding_file filename
    return nil if filename.to_s.empty?
    trimmed_name = filename.split('?')[0]
    return 'Gemfile.lock'  if (/Gemfile\z/ =~ trimmed_name) == 0
    return 'composer.lock' if (/composer.json\z/ =~ trimmed_name) == 0
    return 'Podfile.lock'  if (/Podfile\z/ =~ trimmed_name) == 0
    return nil
  end

  
  def self.index( user, filter = {}, sort = nil)
    filter_options            = {:parent_id => nil}
    filter_options[:language] = filter[:language]  if filter[:language] && !filter[:language].to_s.eql?('ALL')
    filter_options[:name]     = /#{filter[:name]}/i if filter[:name] && !filter[:name].to_s.strip.empty?
    if filter[:scope].to_s == 'all_public'
      filter_options[:public] = true 
    else 
      filter_options[:user_id] = user.ids 
    end

    case sort
    when 'out_dated' 
      Project.where( filter_options ).desc(:out_number_sum).asc(:name)
    when 'license_violations'
      Project.where( filter_options ).desc(:licenses_red_sum).asc(:name)
    else 
      Project.where( filter_options ).asc(:name).desc(:licenses_red_sum)
    end
  end


  def self.find id
    Project.find_by_id( id )
  rescue => e
    log.error e.message
    nil
  end

  
  def self.find_child parent_id, child_id
    Project.where( :id => child_id, :parent_id => parent_id ).first
  rescue => e
    log.error e.message
    nil
  end


  def self.store project
    raise "project is nil." if project.nil?

    if project.allow_zero_deps != true && (project.dependencies.nil? || project.dependencies.empty?)
      raise "Could not find a single dependency in the project."
    end

    ensure_unique_ga( project )
    ensure_unique_scm( project )

    default_lwl_id = LicenseWhitelistService.fetch_default_id project.user 
    project.license_whitelist_id = default_lwl_id
    project.make_project_key!
    if project.save
      project.save_dependencies
      update_license_numbers!( project )
      ProjectdependencyService.update_security project
      SyncService.sync_project_async project # For Enterprise environment only! 
    else
      err_msg = "Can't save project: #{project.errors.full_messages.to_json}"
      log.error err_msg
      raise err_msg
    end
    project
  end


  def self.ensure_unique_ga project 
    return true if Settings.instance.projects_unique_ga == false 
    return true if project.group_id.to_s.empty? && project.artifact_id.to_s.empty? 
    
    project = Project.find_by_ga( project.group_id, project.artifact_id )    
    return true if project.nil? 

    err_msg = "A project with same GroupId and ArtifactId exist already. Project ID: #{project.id.to_s}"
    log.error err_msg
    raise err_msg
  end


  def self.ensure_unique_scm project 
    return true if Settings.instance.projects_unique_scm == false 
    return true if project.scm_fullname.to_s.empty?
    
    project = Project.where(:source => project.source, :scm_fullname => project.scm_fullname, :scm_branch => project.scm_branch, :s3_filename => project.s3_filename).first
    return true if project.nil? 

    err_msg = "The project file is already monitored by VersionEye. Project ID: #{project.id.to_s}"
    log.error err_msg
    raise err_msg
  end

  
  def self.merge_by_ga group_id, artifact_id, subproject_id, user_id
    parent = Project.by_user_id(user_id).find_by_ga(group_id, artifact_id)
    resp = merge( parent.id.to_s, subproject_id, user_id )
    update_sums parent
    resp 
  end


  def self.merge project_id, subproject_id, user_id 
    project    = find project_id
    subproject = find subproject_id 
    return false if project.nil? || subproject.nil?  
    return false if subproject.parent_id        # subproject has already a parent project!
    return false if project.parent_id           # project is already a subproject!
    return false if !subproject.children.empty? # subproject is a parent project!
    return false if project.id.to_s.eql?(subproject.id.to_s) # project & subproject are the same! 

    user = User.find user_id
    return false if user.nil? 
    
    if !project.collaborator?(user)
      raise "User has no permission to merge this project!"
    end

    subproject.parent_id = project.id 
    subproject.save

    cache.delete project.id.to_s
    cache.delete subproject.id.to_s

    ProjectUpdateService.update_async project 
    true 
  end


  def self.unmerge project_id, subproject_id, user_id 
    project    = find project_id
    subproject = Project.where( :id => subproject_id, :parent_id => project_id ).first
    return false if project.nil? || subproject.nil? 

    user = User.find user_id
    return false if user.nil? 
    
    if !project.collaborator?(user)
      raise "User has no permission to unmerge this project!"
    end

    subproject.parent_id = nil 
    subproject.save 

    cache.delete project.id.to_s
    cache.delete subproject.id.to_s

    ProjectUpdateService.update_async project 
    ProjectUpdateService.update_async subproject 
    true 
  end


  def self.destroy_by user, project_id
    project = Project.find_by_id( project_id )
    return false if project.nil?
    
    if project.collaborator?( user ) || user.admin == true 
      destroy project 
    else 
      raise "User has no permission to delete this project!"
    end
  end

  
  def self.destroy project
    return false if project.nil?  
    
    project.children.each do |child_project| 
      destroy_single child_project.id 
    end
    destroy_single project.id
  end

  
  def self.destroy_single project_id
    project = Project.find_by_id( project_id )
    return false if project.nil?

    project.remove_dependencies
    project.remove_collaborators
    project.remove
  end


  # Returns a map with
  #  - :key => "language_prod_key"
  #  - :value => "Array of project IDs where the prod_key is used"
  def self.user_product_index_map user, add_collaborated = true
    indexes = Hash.new
    projects = user.projects

    if projects
      project_prod_index projects, indexes
    end

    return indexes if add_collaborated == false

    collaborated_projects = Project.by_collaborator(user)
    if collaborated_projects
      project_prod_index collaborated_projects, indexes
    end

    indexes
  end

  def self.project_prod_index projects, indexes
    projects.each do |project|
      next if project.nil?

      project.dependencies.each do |dep|
        next if dep.nil? or dep.product.nil?

        product = dep.product
        prod_id = "#{product.language_esc}_#{product.prod_key}"
        indexes[prod_id] = [] unless indexes.has_key?(prod_id)
        indexes[prod_id] << {:project_id => project[:_id].to_s, :version_requested => dep.version_requested}
      end
    end
    indexes
  end


  def self.insecure?( project )
    return true if insecure_single?( project )
    project.children.each do |child_project|
      return true if insecure_single?( child_project )
    end
    false
  end


  def self.insecure_single?( project )
    return false if project.language.eql?(Product::A_LANGUAGE_PHP) && !project.filename.eql?('composer.lock')
    
    project.projectdependencies.each do |dep|
      return true if !dep.sv_ids.to_a.empty?
    end
    return false 
  end


  def self.outdated?( project )
    return true if outdated_single?( project )
    project.children.each do |child_project|
      return true if outdated_single?( child_project )
    end
    false
  end

  def self.outdated_single?( project )
    project.projectdependencies.each do |dep|
      next if dep.scope.to_s.eql?(Dependency::A_SCOPE_DEVELOPMENT)
      next if dep.scope.to_s.eql?(Dependency::A_SCOPE_TEST)
      return true if ProjectdependencyService.outdated?( dep )
    end
    false
  end


  def self.outdated_dependencies( project, force_update = false )
    outdated_dependencies = Array.new
    project.projectdependencies.each do |dep|
      ProjectdependencyService.update_outdated!( dep ) if force_update
      outdated_dependencies << dep if ProjectdependencyService.outdated?( dep )
    end
    outdated_dependencies
  end


  # Returns the projectdependencies which have unknown licenses
  def self.unknown_licenses( project )
    unknown = Array.new
    return unknown if project.nil? || project.projectdependencies.empty?

    project.projectdependencies.each do |dep|
      product = dep.product
      if product.nil?
        unknown << dep
        next
      end
      product.version = dep.version_requested
      unknown << dep if product.licenses.nil? || product.licenses.empty?
    end
    unknown
  end


  # Returns the projectdependencies which violate the license whitelist.
  def self.red_licenses( project )
    red = []
    return red if project.nil? || project.projectdependencies.empty? || project.license_whitelist_id.nil?

    whitelist = project.license_whitelist
    return red if whitelist.nil?
    return red if whitelist.license_elements.nil? || whitelist.license_elements.empty?

    project.projectdependencies.each do |dep|
      product = dep.product
      next if product.nil?

      product.version = dep.version_requested
      next if product.licenses.nil? || product.licenses.empty?

      on_white_list = on_whitelist?( product, whitelist )
      red << dep if !on_white_list
    end
    red
  end


  def self.update_license_numbers!( project )
    return nil if project.nil? || project.projectdependencies.empty?

    ProjectdependencyService.update_licenses project
    project.licenses_unknown = unknown_licenses( project ).count
    project.licenses_red = red_licenses( project ).count
    project.save
  end


  def self.update_sums( project )
    return if project.nil? 

    if project.children.empty? 
      project.sum_own!
      return nil 
    end

    dep_hash = {}
    project.sum_reset!
    project.children.each do |child_project| 
      update_numbers_for project, child_project, dep_hash
      child_project.sum_own!
    end
    update_numbers_for project, project, dep_hash
    project.save 
    project 
  end

  
  private 

  
    def self.update_numbers_for project, child_project, dep_hash = {}
      child_project.dependencies.each do |dep| 
        key = "#{dep.language}:#{dep.possible_prod_key}:#{dep.version_requested}"
        next if dep_hash.include? key 

        product = dep.product
        dep_hash[key] = dep
        project.dep_number_sum       += 1 
        project.out_number_sum       += 1 if dep.outdated 
        project.unknown_number_sum   += 1 if dep.unknown? 
        project.licenses_unknown_sum += 1 if product.nil? || product.licenses.nil? || product.licenses.empty?
        project.licenses_red_sum     += 1 if red_license?( dep )
      end
      dep_hash
    end


    def self.red_license? projectdependency 
      lcs = projectdependency.license_caches
      return false if lcs.nil? || lcs.empty?
        
      lcs.each do |lc| 
        return true if lc.on_whitelist == false 
      end
      return false 
    end


    def self.on_whitelist?( product, whitelist )
      product.licenses.each do |license|
        on_whitelist = whitelist.include_license_substitute?( license.name_substitute )
        return true if on_whitelist
      end
      false 
    end


end

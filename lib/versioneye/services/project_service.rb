class ProjectService < Versioneye::Service


  def self.type_by_filename filename
    return nil if filename.to_s.empty?
    trimmed_name = filename.split('?')[0]
    return Project::A_TYPE_RUBYGEMS  if (!(/Gemfile$/ =~ trimmed_name).nil?)        or (!(/Gemfile.lock$/  =~ trimmed_name).nil?)
    return Project::A_TYPE_COMPOSER  if (!(/composer.json$/ =~ trimmed_name).nil?)  or (!(/composer.lock$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_PIP       if (!(/requirements.txt$/ =~ trimmed_name).nil?)  or (!(/setup.py$/ =~ trimmed_name).nil?) or (!(/pip.log$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_NPM       if (!(/package.json$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_GRADLE    if (!(/.gradle$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_MAVEN2    if (!(/pom.xml$/ =~ trimmed_name).nil?)  or (!(/pom.json$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_LEIN      if (!(/project.clj$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_BOWER     if (!(/bower.json$/ =~ trimmed_name).nil?)
    return Project::A_TYPE_COCOAPODS if (!(/Podfile$/ =~ trimmed_name).nil?)  or (!(/.podfile$/ =~ trimmed_name).nil?) or (!(/Podfile.lock$/ =~ trimmed_name).nil?)
    return nil
  end

  def self.set_prod_type_if_nil dependency
    return nil if dependency.nil?
    return nil if dependency.prod_type
    dependency.prod_type = Project::A_TYPE_RUBYGEMS  if dependency.language.eql?(Product::A_LANGUAGE_RUBY)
    dependency.prod_type = Project::A_TYPE_COMPOSER  if dependency.language.eql?(Product::A_LANGUAGE_PHP)
    dependency.prod_type = Project::A_TYPE_PIP       if dependency.language.eql?(Product::A_LANGUAGE_PYTHON)
    dependency.prod_type = Project::A_TYPE_NPM       if dependency.language.eql?(Product::A_LANGUAGE_NODEJS)
    dependency.prod_type = Project::A_TYPE_MAVEN2    if dependency.language.eql?(Product::A_LANGUAGE_JAVA)
    dependency.prod_type = Project::A_TYPE_LEIN      if dependency.language.eql?(Product::A_LANGUAGE_CLOJURE)
    dependency.prod_type = Project::A_TYPE_BOWER     if dependency.language.eql?(Product::A_LANGUAGE_JAVASCRIPT)
    dependency.prod_type = Project::A_TYPE_COCOAPODS if dependency.language.eql?(Product::A_LANGUAGE_OBJECTIVEC)
    dependency
  end


  def self.find id
    project = Project.find_by_id( id )
    return nil if project.nil?

    project.dependencies.each do |dep|
      ProjectdependencyService.outdated?( dep )
    end
    project
  end


  def self.upload file, user = nil, api_created = false
    project_name        = file['datafile'].original_filename
    filename            = S3.upload_fileupload(file )
    url                 = S3.url_for( filename )
    project             = ProjectService.build_project( url, project_name )
    project.s3_filename = filename
    project.source      = Project::A_SOURCE_UPLOAD
    project.user        = user
    project.api_created = api_created
    project.make_project_key!
    project
  end

  def self.store project
    return false if project.nil?

    project.make_project_key!
    project.save
    if project.dependencies && !project.dependencies.empty? && project.save
      project.save_dependencies
      return true
    else
      log.error "Can't save project: #{project.errors.full_messages.to_json}"
      return false
    end
  end


=begin
  This methods is doing 3 things
   - Importing a project_file from GitHub
   - Parsing the project_file to a new project
   - Storing the new project to DB
=end
  def self.import_from_github user, repo_name, filename, branch = 'master'
    private_project = Github.private_repo? user.github_token, repo_name
    unless allowed_to_add_project?(user, private_project)
      return "Please upgrade your plan to monitor the selected project."
    end

    project_file = Github.fetch_project_file_from_branch(repo_name, filename, branch, user[:github_token] )
    if project_file.nil?
      error_msg = " Didn't find any project file of a supported package manager."
      log.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      return error_msg
    end

    file_bin = project_file[:content]
    file_txt = Base64.decode64(file_bin)

    full_name = project_file[:name]
    file_name = full_name.split("/").last
    rnd = SecureRandom.urlsafe_base64(7)
    file_path = "/tmp/#{rnd}_#{file_name}"
    File.open(file_path, 'w') { |file| file.write( file_txt ) }

    parsed_project = build_from_file_path file_path
    parsed_project.update_attributes({
      name: repo_name,
      project_type: project_file[:type],
      user_id: user.id.to_s,
      source: Project::A_SOURCE_GITHUB,
      private_project: private_project,
      scm_fullname: repo_name,
      scm_branch: branch,
      s3_filename: project_file[:name],
      url: project_file[:url]
    })

    return parsed_project if store( parsed_project )
  end


=begin
  This methods is doing 3 things
   - Importing a project_file from Bitbucket
   - Parsing the project_file to a new project
   - Storing the new project to DB
=end
  def self.import_from_bitbucket(user, repo_name, filename, branch = "master")
    repo = BitbucketRepo.by_user(user).by_fullname(repo_name).shift
    private_project = repo[:private]
    unless allowed_to_add_project?(user, private_project)
      return "Please upgrade your plan to monitor the selected project."
    end

    content = Bitbucket.fetch_project_file_from_branch(
      repo_name, branch, filename,
      user[:bitbucket_token], user[:bitbucket_secret]
    )
    if content.nil? or content == "error"
      error_msg = " Didn't find any project file of a supported package manager."
      log.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      return error_msg
    end

    s3_info = S3.upload_file_content(content, filename)
    if s3_info.nil? && !s3_info.has_key?('filename') && !s3_info.has_key?('s3_url')
      error_msg = "Connectivity issues - can't import project file for parsing."
      log.error " Can't upload file to s3: #{project_file[:name]}"
      return error_msg
    end

    project_type = ProjectService.type_by_filename( filename )
    parsed_project = build_from_url( s3_info['s3_url'], project_type)
    parsed_project.update_attributes({
      name: repo_name,
      project_type: project_type,
      user_id: user.id.to_s,
      source: Project::A_SOURCE_BITBUCKET,
      scm_fullname: repo_name,
      scm_branch: branch,
      private_project: private_project,
      s3_filename: s3_info['filename'],
      url: s3_info['s3_url']
    })

    return parsed_project if store( parsed_project )
  end


  def self.build_project( url, project_name )
    project      = ProjectService.build_from_url( url )
    if project.name.nil? || project.name.empty?
      project.name = project_name
    end
    project
  end


  def self.build_from_file_path(file_path, project_type = nil)
    project_type = type_by_filename(file_path) if project_type.nil?
    parser       = ParserStrategy.parser_for( project_type, file_path )
    parser.parse_file file_path
  rescue => e
    log.error "Error in build_from_file_path(#{file_path}) -> #{e.message}"
    log.error e.backtrace.join("\n")
    Project.new
  end


  def self.build_from_url(url, project_type = nil)
    project_type = type_by_filename(url) if project_type.nil?
    parser       = ParserStrategy.parser_for( project_type, url )
    parser.parse url
  rescue => e
    log.error "Error in build_from_url(url) -> #{e.message}"
    log.error e.backtrace.join("\n")
    Project.new
  end


  def self.destroy project_id
    project = Project.find_by_id( project_id )
    if project.s3_filename && !project.s3_filename.empty?
      S3.delete( project.s3_filename )
    end
    project.remove_dependencies
    project.remove_collaborators
    project.remove
  end


  def self.allowed_to_add_project?( user, private_project )
    return true if !private_project
    return true if Settings.instance.projects_unlimited

    private_project_count = Project.private_project_count_by_user( user.id )
    max = user.free_private_projects
    if user.plan
      max += user.plan.private_projects
    end
    return false if private_project_count >= max
    return true
  end


  # Returns a map with
  #  - :key => "language_prod_key"
  #  - :value => "Array of project IDs where the prod_key is used"
  def self.user_product_index_map user, add_collaborated = true
    indexes = Hash.new
    projects = user.projects
    return indexes if projects.nil?

    projects.each do |project|
      next if project.nil?
      project.dependencies.each do |dep|
        next if dep.nil? or dep.product.nil?
        product = dep.product
        prod_id = "#{product.language_esc}_#{product.prod_key}"
        indexes[prod_id] = [] unless indexes.has_key?(prod_id)
        indexes[prod_id] << project[:_id].to_s
      end
    end

    collaborated_projects = Project.by_collaborator(user)
    if add_collaborated and !collaborated_projects.nil?
      collaborated_projects.each do |project|
        next if project.nil?
        project.dependencies.each do |dep|
          next if dep.nil? or dep.product.nil?
          product = dep.product
          prod_id = "#{product.language_esc}_#{product.prod_key}"
          indexes[prod_id] = [] unless indexes.has_key?(prod_id)
          indexes[prod_id] << project[:_id].to_s
        end
      end
    end

    indexes
  end


  def self.badge_for_project project_id
    log.debug "project_id: #{project_id}"
    badge = cache.get project_id.to_s
    log.info "badge: #{badge}"
    return badge if badge

    project = Project.find_by_id project_id.to_s
    return "unknown" if project.nil?

    update_badge_for_project project
  end


  def self.update_badge_for_project project
    badge    = outdated?(project) ? 'out-of-date' : 'up-to-date'
    cache.set( project.id.to_s, badge, 21600) # TTL = 6.hour
    badge
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    "unknown"
  end


  def self.outdated?( project )
    project.projectdependencies.each do |dep|
      return true if ProjectdependencyService.outdated?( dep )
    end
    false
  end

  def self.outdated_dependencies( project )
    outdated_dependencies = Array.new
    project.projectdependencies.each do |dep|
      outdated_dependencies << dep if ProjectdependencyService.outdated?( dep )
    end
    outdated_dependencies
  end

end

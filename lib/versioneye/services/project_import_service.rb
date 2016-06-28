class ProjectImportService < Versioneye::Service

  A_ENV_ENTERPRISE = "enterprise"
  A_TASK_RUNNING = 'running'
  A_TASK_TTL     = 60 # 60 seconds = 1 minute


  def self.import_all_github user, pfs = ['Gemfile', 'package.json', 'pom.xml', 'bower.json', 'Podfile', 'build.gradle']
    user.github_repos.where(:fullname => /\Ablinkist/, :private => true).each do |repo|
      next if repo.branches.to_a.empty?

      branch = ''
      branch = 'master'  if repo.branches.include?("master")
      branch = 'develop' if repo.branches.include?('develop')
      next if branch.empty?

      import_all_github_from user, repo, branch, pfs
    end
  end

  def self.import_all_github_from user, repo, branch, pfs
    repo.project_files[branch].each do |pf|
      path = pf['path']
      if pfs.include?( path )
        p "import - #{user.username} - #{repo.fullname} - #{path} - #{branch}"
        import_from_github user, repo.fullname, pf['path'], branch
      end
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.import_from_github_async user, repo_name, filename, branch = 'master', orga_id = ''
    key = "github:::#{user.username}:::#{repo_name}:::#{filename}:::#{branch}:::#{orga_id}"
    task_status( key ){ GitRepoFileImportProducer.new( key ) }
  end

  def self.import_from_github user, repo_name, filename, branch = 'master', orga_id = ''
    private_project = Github.private_repo? user.github_token, repo_name
    check_permission_for_github_repo user, repo_name, private_project

    project_file = Github.fetch_project_file_from_branch(repo_name, filename, branch, user[:github_token] )
    if project_file.nil?
      log.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      raise " Didn't find any project file of a supported package manager."
    end

    file_txt  = GitHubService.pure_text_from project_file
    file_name = GitHubService.filename_from project_file
    parser    = ProjectParseService.parser_for file_name
    project   = ProjectParseService.parse_content parser, file_txt, file_name

    if project.nil?
      raise "The project file could not be parsed. Maybe it's not valid?"
    end

    organisation_id = nil
    organisation_id = orga_id if !orga_id.to_s.empty?
    project.update_attributes({
      name: repo_name,
      project_type: project_file[:type],
      user_id: user.id.to_s,
      organisation_id: organisation_id,
      source: Project::A_SOURCE_GITHUB,
      private_project: private_project,
      scm_fullname: repo_name,
      scm_branch: branch,
      s3_filename: filename,
      url: project_file[:url],
      period: Settings.instance.default_project_period,
      public: Settings.instance.default_project_public
    })

    project = ProjectService.store( project )
    merge_into_parent project, user
    ProjectService.update_sums( project )
    project
  end


  def self.import_from_bitbucket_async user, repo_name, filename, branch = 'master', orga_id = ''
    key = "bitbucket:::#{user.username}:::#{repo_name}:::#{filename}:::#{branch}:::#{orga_id}"
    task_status( key ){ GitRepoFileImportProducer.new( key ) }
  end


  def self.import_from_bitbucket(user, repo_name, filename, branch = "master", orga_id = '')
    repo = BitbucketRepo.by_user(user).by_fullname(repo_name).shift
    private_project = repo[:private]

    check_permission_for_bitbucket_repo user, private_project

    project_file = Bitbucket.fetch_project_file_from_branch(
      repo_name, branch, filename,
      user[:bitbucket_token], user[:bitbucket_secret]
    )

    if project_file.nil? || project_file == "error" || project_file.eql?("Not Found")
      log.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      return " Didn't find any project file of a supported package manager."
    end

    project_type = ProjectService.type_by_filename filename
    file_name = filename.split("/").last
    parser  = ProjectParseService.parser_for file_name
    project = ProjectParseService.parse_content parser, project_file, file_name

    if project.nil?
      raise "The project file could not be parsed. Maybe it's not valid?"
    end

    revision = BitbucketRepo.revision_for user, repo_name, branch, filename

    organisation_id = nil
    organisation_id = orga_id if !orga_id.to_s.empty?
    project.update_attributes({
      name: repo_name,
      project_type: project_type,
      user_id: user.id.to_s,
      organisation_id: organisation_id,
      source: Project::A_SOURCE_BITBUCKET,
      scm_fullname: repo_name,
      scm_branch: branch,
      scm_revision: revision,
      private_project: private_project,
      s3_filename: filename,
      url: nil,
      period: Settings.instance.default_project_period,
      public: Settings.instance.default_project_public
    })

    project = ProjectService.store( project )
    merge_into_parent project, user
    ProjectService.update_sums( project )
    project
  end


  def self.import_from_stash_async user, repo_name, filename, branch = 'master', orga_id = ''
    key = "stash:::#{user.username}:::#{repo_name}:::#{filename}:::#{branch}:::#{orga_id}"
    task_status( key ){ GitRepoFileImportProducer.new( key ) }
  end

  def self.import_from_stash(user, repo_name, filename, branch = "master", orga_id = '')
    repo = StashRepo.by_user(user).by_fullname(repo_name).shift
    private_project = !repo[:public_repo]
    unless allowed_to_add_project?(user, private_project)
      return "Please upgrade your plan to monitor the selected project."
    end

    project_file = StashService.fetch_file_from_stash(user, repo, filename, branch)
    if project_file.nil? || project_file.empty? || project_file == "error" || project_file.eql?("Not Found")
      log.error " Can't import project file `#{filename}` from #{repo_name} branch #{branch} "
      return " Didn't find any project file of a supported package manager."
    end

    project_type = ProjectService.type_by_filename filename
    content = StashService.pure_text_from project_file
    project = StashService.parse_content content, filename

    if project.nil?
      raise "The project file could not be parsed. Maybe it's not valid?"
    end

    organisation_id = nil
    organisation_id = orga_id if !orga_id.to_s.empty?
    project.update_attributes({
      name: repo_name,
      project_type: project_type,
      user_id: user.id.to_s,
      organisation_id: organisation_id,
      source: Project::A_SOURCE_STASH,
      scm_fullname: repo_name,
      scm_branch: branch,
      private_project: private_project,
      s3_filename: filename,
      url: nil,
      period: Settings.instance.default_project_period,
      public: Settings.instance.default_project_public
    })

    project = ProjectService.store( project )
    merge_into_parent project, user
    ProjectService.update_sums( project )
    project
  end


  def self.import_from_url( url, project_name, user, orga_id = nil)
    project = build_from_url( url )
    return nil if project.nil?

    if project.name.nil? || project.name.empty?
      project.name = project_name
    end

    project.update_attributes({
      user_id: user.id.to_s,
      source: Project::A_SOURCE_URL,
      s3_filename: project_name,
      url: url,
      period: Settings.instance.default_project_period,
      public: Settings.instance.default_project_public,
      organisation_id: orga_id
    })

    project = ProjectService.store( project )
    ProjectService.update_sums( project )
    project
  end


  # This is currently used by the VersionEye API project and the file upload in the Web UI.
  def self.import_from_upload file, user = nil, api_created = false, orga_id = nil
    project_name = file['datafile'].original_filename
    project = ProjectParseService.project_from file
    if project.nil?
      raise "project file could not be parsed. Maybe the file is empty? Or not valid?"
    end

    if project.name.to_s.empty?
      project_name = file['datafile'].original_filename
      project.s3_filename = project_name
      project.name        = project_name
    end
    project.source      = Project::A_SOURCE_UPLOAD
    project.source      = Project::A_SOURCE_API if api_created
    project.user        = user
    project.period      = Settings.instance.default_project_period
    project.public      = Settings.instance.default_project_public
    project.organisation_id = orga_id

    project = ProjectService.store( project )
    ProjectService.update_sums( project )
    project
  end


  def self.check_permission_for_github_repo user, repo_name, private_project = nil
    if private_project.nil?
      private_project = Github.private_repo? user.github_token, repo_name
    end
    if allowed_to_add_project?(user, private_project) == false
      raise "The selected project file is in a private repository. Please upgrade your plan to monitor the selected project."
    end
    true
  end


  def self.check_permission_for_bitbucket_repo user, private_project
    if allowed_to_add_project?(user, private_project) == false
      raise "The selected project file is in a private repository. Please upgrade your plan to monitor the selected project."
    end
    true
  end


  def self.allowed_to_add_project?( user, private_project )
    env = Settings.instance.environment
    return allowed_to_add_e_project?() if env.eql?( A_ENV_ENTERPRISE )
    return allowed_to_add?( user, private_project )
  end


  def self.task_status( key )
    task_status = cache.get( key )
    if task_status &&
      ( task_status.to_s == A_TASK_RUNNING ||
        task_status.to_s.match(/\Adone_/)  ||
        task_status.to_s.match(/\Aerror_/) )
      log.debug "status for #{key} is #{task_status}"
      return task_status
    end

    task_status = A_TASK_RUNNING
    cache.set( key, task_status, A_TASK_TTL )

    yield

    task_status
  end


  private


    def self.merge_into_parent project, user
      parent = fetch_possible_parent project
      ProjectService.merge(parent.ids, project.ids, user.ids) if parent
    end


    def sefl.fetch_possible_parent project
      if project.organisation_id
        return Project.where(:organisation_id => project.organisation_id, :scm_fullname => project.scm_fullname, :scm_branch => project.scm_branch, :parent_id => nil).first
      end
      Project.where(:user_id => project.user_id, :scm_fullname => project.scm_fullname, :scm_branch => project.scm_branch, :parent_id => nil).first
    end


    # Allowed to add Enterprise project?
    def self.allowed_to_add_e_project?
      env        = Settings.instance.environment
      e_projects = GlobalSetting.get env, 'e_projects'
      return false if e_projects.to_s.empty?

      project_count = Project.count
      return false if project_count.to_i >= e_projects.to_i

      return true
    end


    def self.allowed_to_add?( user, private_project )
      return true if private_project == false || private_project.to_s.empty?

      private_project_count = Project.private_project_count_by_user( user.id )
      max = user.free_private_projects
      if user.plan
        max += user.plan.private_projects
      end
      return false if private_project_count >= max
      return true
    end


    def self.build_from_url(url, project_type = nil)
      project_type = ProjectService.type_by_filename(url) if project_type.nil?
      parser       = ParserStrategy.parser_for( project_type, url )
      parser.parse url
    rescue => e
      log.error "Error in build_from_url( #{url} ) -> #{e.message}"
      log.error e.backtrace.join("\n")
      nil
    end


end

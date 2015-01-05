require 'benchmark'
require 'dalli'

class GitHubService < Versioneye::Service

  A_TASK_NIL     = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE    = 'done'
  A_TASK_TTL     = 1800 # 1800 seconds = 30 minutes


  def self.update_all_repos
    User.all(:timeout => true).live_users.where(:github_scope => 'repo').each do |user|
      update_repos_for_user user
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.update_repos_for_user user
    log.debug "Fetch GitHub Repos for #{user.fullname}."
    user.github_repos.delete_all
    GitHubService.cached_user_repos user
  rescue => e
    log.error "Cant import repos for #{user.fullname} \n #{e.message}"
    log.error e.backtrace.join("\n")
  end


=begin
  Returns github repos for user;
  If user don't have yet any github repos
     or there's been any change on user's github account,
  then trys to read from github
  else it returns cached results from GitHubRepos collection.
  NB! allows only one running task per user;
=end
  def self.cached_user_repos user
    user_task_key = "#{user[:username]}-#{user[:github_id]}"
    task_status   = cache.get( user_task_key )

    if task_status == A_TASK_RUNNING || task_status == A_TASK_DONE
      log.debug "Status for importing repos for `#{user[:fullname]}.` from GitHub: #{task_status}"
      return task_status
    end

    if user[:github_token] and user.github_repos.all.count == 0
      task_status = A_TASK_RUNNING
      cache.set( user_task_key, task_status, A_TASK_TTL )
      GitReposImportProducer.new("github:::#{user.id.to_s}")
    else
      log.info 'Nothing is changed - skipping update.'
      task_status = A_TASK_DONE
    end

    task_status
  end


  def self.status_for user, current_repo
    repo_fullname = current_repo.fullname
    return A_TASK_DONE if current_repo.nil?

    repo_task_key = "github:::#{user.id.to_s}:::#{current_repo.id.to_s}"
    task_status   = cache.get( repo_task_key )

    if task_status == A_TASK_RUNNING || task_status == A_TASK_DONE
      log.debug "Status for importing branches and project files for `#{repo_fullname}.` from GitHub: #{task_status}"
      return task_status
    end

    if current_repo and ( current_repo.branches.nil? || current_repo.branches.empty? )
      task_status = A_TASK_RUNNING
      cache.set( repo_task_key, task_status, A_TASK_TTL )
      GitRepoImportProducer.new( repo_task_key )
    else
      log.info 'Nothing is changed - skipping update.'
      task_status = A_TASK_DONE
    end

    task_status
  end


  def self.update_repo_info user, repo_fullname
    current_repo = GithubRepo.by_user(user).by_fullname(repo_fullname).shift
    if current_repo.nil?
      log.error "User #{user[:username]} has no such repo `#{repo_fullname}`."
      return nil
    end

    token = user[:github_token]
    repo_info = Github.repo_info repo_fullname, token
    git_repo  = GithubRepo.build_or_update user, repo_info
    git_repo  = Github.update_branches git_repo, token
    git_repo  = Github.update_project_files git_repo, token
    git_repo.user_id = user.id
    git_repo.user_login = user.github_login
    git_repo.save

    git_repo
  end


  def self.cache_user_all_repos(user, orga_names)
    user_info = Github.user(user.github_token)
    user[:user_login] = user_info[:login] if user_info.is_a?(Hash)

    log.info "reading user repos for user: #{user.fullname}"
    cache_user_repos(user)
    orga_names.each do |orga_name|
      log.info "reading repos for orga: #{orga_name}"
      cache_user_orga_repos(user, orga_name)
    end
  end


  def self.pure_text_from project_file
    file_bin = project_file[:content]
    Base64.decode64(file_bin)
  rescue => e 
    log.error e.message
    log.error e.backtrace.join("\n")
    ''
  end

  def self.filename_from project_file
    full_name = project_file[:name]
    full_name.split("/").last
  rescue => e 
    log.error e.message
    log.error e.backtrace.join("\n")
    ''
  end


  private


    def self.cache_user_repos( user )
      url = nil
      begin
        data = Github.user_repos(user, url)
        url = data[:paging]["next"]
      end while not url.nil?
    end


    def self.cache_user_orga_repos(user, orga_name)
      url = nil
      begin
        data = Github.user_orga_repos(user, orga_name, url)
        url = data[:paging]["next"]
      end while not url.nil?
    end


end

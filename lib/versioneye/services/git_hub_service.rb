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
    log.debug "Importing repos for #{user.fullname}."
    user.github_repos.delete_all
    GitHubService.cached_user_repos user
    log.debug  "Got #{user.github_repos.count} repos for #{user.fullname}."
    user.github_repos.all
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

    if task_status == A_TASK_RUNNING
      log.debug "We are still importing repos for `#{user[:fullname]}.`"
      return task_status
    end

    if user[:github_token] and user.github_repos.all.count == 0
      task_status = A_TASK_RUNNING
      cache.set( user_task_key, task_status, A_TASK_TTL )
      GithubReposImportProducer.new("#{user.id.to_s}")
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
    puts "Going to cache repositories for #{user.username}."
    user_info = Github.user(user.github_token)
    user[:user_login] = user_info['login'] if user_info.is_a?(Hash)

    log.info "reading user repos"
    cache_user_repos(user)
    orga_names.each do |orga_name|
      log.info "reading repos for orga: #{orga_name}"
      cache_user_orga_repos(user, orga_name)
    end
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


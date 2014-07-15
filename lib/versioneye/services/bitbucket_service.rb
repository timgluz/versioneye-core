require 'benchmark'
require 'dalli'

class BitbucketService < Versioneye::Service

  A_TASK_NIL     = nil
  A_TASK_RUNNING = 'running'
  A_TASK_DONE    = 'done'
  A_MAX_WORKERS  = 16
  A_TTL = 600 # 600 seconds = 10 minutes


  def self.update_repo_info(user, repo_fullname)
    current_repo = user.bitbucket_repos.where(fullname: repo_fullname).shift
    if current_repo.nil?
      log.error "User #{user[:username]} has no such repo `#{repo_fullname}`"
      return nil
    end

    repo_info     = Bitbucket.repo_info repo_fullname, user[:bitbucket_token], user[:bitbucket_secret]
    repo_branches = Bitbucket.repo_branches repo_fullname, user[:bitbucket_token], user[:bitbucket_secret]
    repo_files    = Bitbucket.repo_project_files repo_fullname, user[:bitbucket_token], user[:bitbucket_secret]

    updated_repo = BitbucketRepo.build_new(user, repo_info, repo_branches, repo_files)
    current_repo.update_attributes(updated_repo.attributes)
    current_repo
  end


  def self.cached_user_repos user
    user_task_key = "#{user[:username]}-bitbucket"
    task_status = cache.get(user_task_key)

    if task_status == A_TASK_RUNNING
      log.debug "Still importing data for #{user[:username]} from bitbucket"
      return task_status
    end

    if user[:bitbucket_token] and user.bitbucket_repos.all.count == 0
      task_status =  A_TASK_RUNNING
      cache.set( user_task_key, task_status, A_TTL )
      BitbucketReposImportProducer.new("#{user.id.to_s}")
    else
      log.info "Nothing to import - maybe clean user's repo?"
      task_status = A_TASK_DONE
    end

    task_status
  end


  def self.cache_user_all_repos(user)
    puts "Going to cache users repositories."

    cache_repos( user, user[:bitbucket_id] )

    user_orgs = Bitbucket.user_orgs(user)
    user_orgs.each do |org|
      self.cache_repos(user, org)
    end

    # Import missing invited repos
    cache_invited_repos(user)
  end


  def self.cache_repos(user, owner_name)
    token  = user[:bitbucket_token]
    secret = user[:bitbucket_secret]
    repos  = Bitbucket.read_repos(owner_name, token, secret)

    # Add information about branches and project files
    repos.each do |repo|
      add_repo( user, repo, token, secret )
    end

    return true
  end


  def self.cache_invited_repos(user)
    token  = user[:bitbucket_token]
    secret = user[:bitbucket_secret]
    repos  = Bitbucket.read_repos_v1( token, secret )
    if repos.nil? or repos.empty?
      log.error "cache_invited_repos | didnt get any repos from APIv1."
      return false
    end

    user.reload
    existing_repo_fullnames  = Set.new user.bitbucket_repos.map(&:fullname)
    missing_repos = repos.keep_if {|repo| existing_repo_fullnames.include?(repo[:full_name]) == false}
    invited_repos = missing_repos.delete_if do |repo|
      # Remove other people forks
      repo.has_key?(:fork_of) and repo[:fork_of].is_a?(Hash) and repo[:fork_of][:owner] == user[:bitbucket_id]
    end
    # Add missing repos
    invited_repos.each do |old_repo|
      repo = Bitbucket.repo_info(old_repo[:full_name], token, secret) #fetch repo info from api2
      if repo.nil?
        log.error "cache_invited_repos | didnt get repo info for `#{old_repo[:full_name]}`"
        next
      end
      add_repo(user, repo, token, secret)
    end
    return true
  end


  def self.add_repo(user, repo, token, secret)
    repo_name = repo[:full_name]
    branches  = Bitbucket.repo_branches(repo_name, token, secret)
    files     = Bitbucket.repo_project_files(repo_name, token, secret)
    BitbucketRepo.create_new(user, repo, branches, files )
  end


end

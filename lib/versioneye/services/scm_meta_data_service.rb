class ScmMetaDataService < Versioneye::Service


  def self.update_all_users
    UserService.all_users_paged do |users|
      users.each do |user|
        update_for user
      end
    end
  end


  def self.update_for user
    log.info "update smc meta data for #{user.username}"
    update_github_repos_for user
    update_bitbucket_repos_for user
    update_stash_repos_for user
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_github_repos_for user
    return if user.github_token.to_s.empty?

    GithubRepo.by_user( user ).delete_all
    user_task_key = "#{user[:username]}-#{user[:github_id]}"
    GitHubService.cache.delete( user_task_key )
    GitHubService.cached_user_repos user
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_bitbucket_repos_for user
    return if user.bitbucket_token.to_s.empty?

    BitbucketRepo.by_user( user ).delete_all
    user_task_key = "#{user[:username]}-bitbucket"
    BitbucketService.cache.delete( user_task_key )
    BitbucketService.cached_user_repos user
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_stash_repos_for user
    return if user.stash_token.to_s.empty?

    StashRepo.by_user( user ).delete_all
    user_task_key = "#{user[:username]}-stash"
    StashService.cache.delete( user_task_key )
    StashService.cached_user_repos user
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end
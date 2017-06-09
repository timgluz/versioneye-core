require 'octokit'
require 'versioneye/models/webhook'

# docs for octokit:
# https://octokit.github.io/octokit.rb/Octokit/Client/Hooks.html

class GithubWebhook < Versioneye::Service

  # creates a new Github hook and saves result into Webhook model
  # returns:
  #   success: Webhook model
  #   failure: nil
  def self.create_project_hook(repo_fullname, project_id, api_key, github_token)
    if repo_fullname.nil? or project_id.nil?
      log.error "create_project_hook: repo_fullname or project_id cant be nil"
      return
    end

    #those are values for our hook endpoit
    hook_configs = build_project_configs(project_id, api_key)
    if hook_configs.nil?
      log.error "create_project_hook: failed to build request body for #{project_id} project hook"
      return nil
    end

    res = create_webhook repo_fullname, github_token, hook_configs
    if res.nil?
      log.error "create_webhook: failed to register webhook on Github."
      return nil
    end

    upsert_project_webhook(res, repo_fullname, project_id)
  end

  # unhooks project on Github and deletes webhooks connected to project
  def self.delete_project_hook(project_id, github_token)
    if github_token.to_s.empty?
      log.error "delete_project_hook: user of #{project_id} has no github token - aborting"
      return false
    end

    hook = Webhook.where(scm: Webhook::A_TYPE_GITHUB, project_id: project_id).first
    if hook.nil?
      log.error "delete_project_hook: found no webhook for project.#{project_id}"
      return false
    end

    is_disconnected = delete_webhook(hook[:fullname], github_token, hook[:hook_id])
    if is_disconnected == false
      log.error "delete_project_hook: failed to disconnect hook on github #{hook[:fullname]} - #{hook[:hook_id]}"
      return false
    end

    hook.delete
    true
  end

#-- API CRUD request makers
  # registers a new webhook and returns results from API
  # params:
  #   repo_fullname: String, fullname of github repo, including owner and repo, 'versioneye/veye'
  #   token : String, github access_token
  #   hook_configs: Hash, config data which Github api will pass to our API
  #   hook_options: Hash, optional, settings for Hoot itself, check doc in header
  def self.create_webhook(repo_fullname, token, hook_configs, hook_options = nil)
    if token.to_s.empty?
      log.error "create_webhook: no api_token attached for #{repo_fullname}"
      return
    end

    #those are values for Github
    hook_options ||= default_hook_options

    client = Octokit::Client.new(access_token: token)
    client.create_hook(repo_fullname, 'web', hook_configs, hook_options)
  rescue => e
    log.error "create_webhook: failed to create webhook for #{repo_fullname}"
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def self.delete_webhook(repo_fullname, token, hook_id)
    if token.to_s.empty?
      log.error "delete_webhook: no api token attached for #{repo_fullname}"
      return false
    end

    client = Octokit::Client.new(access_token: token)
    client.remove_hook(repo_fullname, hook_id)
  rescue => e
    log.error "delete_webhook: failed to remove webhook.#{hook_id} on #{repo_fullname}"
    log.error e.message
    log.error e.backtrace.join('\n')
    false
  end


  # fetches list of registered hooks on the Github repo
  # params:
  #   repo_fullname: String, fullname of github repo, 'versioneye/veye'
  #   token :  String, github access_token
  def self.fetch_repo_hooks(repo_fullname, token)
    if token.to_s.empty?
      log.error "fetch_repo_hooks: no api token attached for #{repo_fullname} request"
      return
    end

    client = Octokit::Client.new(access_token: token)
    client.hooks(repo_fullname)
  rescue => e
    log.error "fetch_repo_hooks: failed to request data from API"
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

#-- persistance helpers
  # updates or creates webhook for Versineye project
  def self.upsert_project_webhook(hook_dt, repo_fullname, project_id)
    if hook_dt.nil? or hook_dt.empty?
      log.error "upsert_project_webhook: got no hook data"
      return
    end

    hook = Webhook.where(
      scm: Webhook::A_TYPE_GITHUB,
      fullname: repo_fullname,
      project_id: project_id
    ).first_or_create

    hook.update(
      hook_id: hook_dt[:id],
      service_name: hook_dt[:name],
      active: hook_dt[:active],
      events: hook_dt[:events],
      config: hook_dt[:config].to_hash,
      repo_url: "github.com/#{repo_fullname}",
      source_url: hook_dt[:url],
      test_url: hook_dt[:test_url],
      ping_url: hook_dt[:ping_url]
    )

    if hook.errors.full_messages.size > 0
      log.error "upsert_project_webhook: failed to save project hook."
      return
    end

    log.info "upsert_project_webhook: upserted a hook for project.#{project_id}"
    hook
  end


  def self.get_api_url
    Settings.instance.github_api_url.gsub(/\/\z/, "")
  end

  def self.default_hook_options
    {
      name: 'web',
      active: true,
      events: ['push', 'pull_request']
    }
  end

  #construct valid hash table to create a new hook
  def self.build_project_configs(project_id, api_key)
    callback_url = Settings.instance.server_url
    callback_url += "/api/v2/github/hook/#{project_id}?api_key=#{api_key}"

    {
      url: callback_url,
      content_type: 'json',
      project_id: project_id,
      api_key: api_key
    }
  end

end

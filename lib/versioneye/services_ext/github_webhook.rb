require 'httparty'
require 'persistent_httparty'
require 'versioneye/models/webhook'

class GithubWebhook < Versioneye::Service
  include HTTParty

  A_USER_AGENT = 'Chrome/28(www.versioneye.com, support@versioneye.com)'
  A_DEFAULT_HEADERS = {
    'Accept' => 'application/vnd.github.v3+json',
    'User-Agent' => A_USER_AGENT,
    'Connection' => 'Keep-Alive'
  }

  persistent_connection_adapter({
    name: 'versioneye_github_client',
    pool_size: 30,
    keep_alive: 30
  })

  #creates a new Github hook and saves result into Webhook model
  def self.create_project_hook(repo_fullname, project_id, api_key, github_token)
    if repo_fullname.nil? or project_id.nil?
      log.error "create_project_hook: repo_fullname or project_id cant be nil"
      return
    end

    payload = build_project_payload(project_id, api_key)
    if payload.nil?
      log.error "create_project_hook: failed to build request body for #{project_id} project hook"
      return nil
    end

    res = create_webhook repo_fullname, github_token, payload

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
  #registers a new webhook and returns results from API
  def self.create_webhook(repo_fullname, token, payload = nil)
    github_api_url = get_api_url
    url = "#{github_api_url}/repos/#{repo_fullname}/hooks"

    post_json url, payload, token
  end

  def self.delete_webhook(repo_fullname, token, hook_id)
    api_url = get_api_url
    url = "#{api_url}/repos/#{repo_fullname}/hooks/#{hook_id}"
    request_headers = build_request_headers token

    res = HTTParty.delete(url, headers: request_headers)

    is_success = (res.is_a?(HTTParty::Response) and res.code.to_i == 204)
    is_success
  rescue => e
    log.error "delete_webhook: failed to remove webhook.#{hook_id} on #{repo_fullname}"
    log.error e.message
    log.error e.backtrace.join('\n')
    false
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
      config: hook_dt[:config],
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


#-- request helpers
  # make HTTP post request
  # params:
  #   url - url to github url
  #   body_hash - hash_table, accepted form data to send to API
  #   token     - string, request token for Github API
  #   raw       - Bool, default false, if true, then it will pass raw HTTParty request object
  def self.post_json( url, body_hash, token, raw = false, updated_at = nil )
    request_headers = build_request_headers token, updated_at
    response = HTTParty.post(url, body: body_hash.to_json, headers: request_headers)
    return response if raw

    catch_github_exception parse_safely( response.body )
  rescue => e
    log.error "ERROR in post_json( #{url} ) error message: #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end

  def self.build_request_headers token, updated_at = nil
    request_headers = A_DEFAULT_HEADERS
    if token
      request_headers["Authorization"] = "token #{token}"
    end

    if updated_at.is_a?(Date) or updated_at.is_a?(DateTime)
      request_headers["If-Modified-Since"] = updated_at.to_datetime.rfc822
    end

    request_headers
  end


  def self.parse_safely(json_txt)
    JSON.parse(json_txt.to_s, symbolize_names: true)

  rescue => e
    log.error "parse_safely: failed to parse `#{json_txt}`"
    log.error e.backtrace.join('\n')
    nil
  end

  def self.get_api_url
    Settings.instance.github_api_url.gsub(/\/\z/, "")
  end

  #construct valid hash table to create a new hook
  def self.build_project_payload(project_id, api_key)
    callback_url = Settings.instance.server_url
    callback_url += "/api/v2/github/hook/#{project_id}?api_key=#{api_key}"

    {
      name: 'web',
      active: true,
      events: ['push', 'pull_request'],
      config: {
        url: callback_url,
        content_type: 'json',
        project_id: project_id,
        api_key: api_key
      }
    }
  end

=begin
  Method that checks does Github sent error message
  If yes, then it'll log it and return nil
  Otherwise it sends object itself
  Github responses for client errors:
  {"message": "Problems parsing JSON"}
=end
    def self.catch_github_exception(data)
      if data.is_a?(Hash) and data.has_key?(:message)
        log.error "Catched exception in response from Github API: #{data}"
        return nil
      end

      return data
    rescue => e
      # by default here should be no message or nil
      # We expect that everything is ok and there is no error message
      log.error e.message
      log.error e.backtrace.join("\n")
      nil
    end


end

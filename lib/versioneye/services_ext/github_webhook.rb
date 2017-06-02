require 'httparty'
require 'persistent_httparty'

class GithubWebHook < Versioneye::Service
  include HTTParty
  persistent_connection_adapter({
    name: 'versioneye_github_client',
    pool_size: 30,
    keep_alive: 30
  })

  #TODO: finish it
  #creates a new Github hook and saves result into Webhook model
  def self.create_project_hook repo_fullname, project_id, api_key, github_token
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repo}/hooks"
    hook_dt = build_project_hook_body( callback_url, project_id, api_key )

    res = post_json url, body_hash, github_token
  end

  def self.delete_webhook(repo, token, hook_id)
    api_url = get_github_api_url
    url = "#{api_url}/repos/#{repo}/hooks/#{hook_id}"

    res = delete(url)
    is_success = res.nil? == false and res.code >= 200 and res.code < 300
    return false if is_success == false

    #if api returned 200, but content include error message
    has_error_message = catch_github_exception(res.body).nil?
    return false if has_error_message

    true
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
  end

  def self.get_api_url
    Settings.instance.github_api_url.gsub(/\/\z/, "")
  end

  #construct valid hash table to create a new hook
  def self.build_project_hook_body(project_id, api_key)
    callback_url = Settings.instance.server_url
    callback_url += "/api/v2/github/hook/#{project_id}?api_key=#{api_key}"

    {
      name: 'web'
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

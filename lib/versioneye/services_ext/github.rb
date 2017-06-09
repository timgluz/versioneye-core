#------------------------------------------------------------------------------
# Github - helper functions to manage Github's data.
#
# NB! For consistancy: every function that returns hash-map, should have
# symbolized keys. For that you can use 2 helpers function:
#
#  * {'a' => 1}.deep_symbolize_keys - encodes keys recursively
#
#  * JSON.parse(json_string, symbolize_names: true)
#
# If you're going to add simple get-request function, then use `get_json`.
# This function builds correct headers and handles Github exceptions.
#
#------------------------------------------------------------------------------

require 'uri'
require 'httparty'
require 'persistent_httparty'

class Github < Versioneye::Service

  A_WORKERS_COUNT = 4
  A_USER_AGENT = 'Chrome/28(www.versioneye.com, support@versioneye.com)'
  A_DEFAULT_HEADERS = {
    'Accept' => 'application/vnd.github.v3+json',
    'User-Agent' => A_USER_AGENT,
    'Connection' => 'Keep-Alive'
  }

  include HTTParty
  persistent_connection_adapter({
    name: 'versioneye_github_client',
    pool_size: 30,
    keep_alive: 30
  })

  def self.token code
    response = Octokit.exchange_code_for_token code, Settings.instance.github_client_id, Settings.instance.github_client_secret
    response.access_token
  end

  def self.user token
    client = OctokitApi.client token
    client.user.to_hash
  rescue => e
    log.error e.message
    log.error e.backtrace.join( "\n" )
    nil
  end

  def self.emails token
    client = OctokitApi.client token
    client.emails
  rescue => e
    log.error e.message
    log.error e.backtrace.join( "\n" )
    nil
  end

  def self.oauth_scopes token
    client = OctokitApi.client token
    client.scopes token
  rescue => e
    log.error e.message
    log.error e.backtrace.join( "\n" )
    ''
  end

  def self.get_github_api_url
    Settings.instance.github_api_url.gsub(/\/\z/, "")
  end

  # Returns how many repos user has. NB! doesnt count orgs
  def self.count_user_repos(user_info)
    n = 0
    return n if user_info[:github_token].nil?

    github_api_url = get_github_api_url
    user_info = get_json("#{github_api_url}/user", user_info[:github_token])
    if user_info
      n = user_info[:public_repos].to_i + user_info[:total_private_repos].to_i
    end
    n
  end

  def self.user_repos user, url = nil, page = 1, per_page = 30
    github_api_url = get_github_api_url
    url = "#{github_api_url}/user/repos?page=#{page}&per_page=#{per_page}&access_token=#{user.github_token}" if url.nil?
    persist_repos(user, url, page, per_page)
  end

  def self.user_orga_repos user, orga_name, url = nil, page = 1, per_page = 30
    github_api_url = get_github_api_url
    url = "#{github_api_url}/orgs/#{orga_name}/repos?access_token=#{user.github_token}&page=#{page}&per_page=#{per_page}" if url.nil?
    persist_repos(user, url, page, per_page)
  end

  def self.repo_info(repo_fullname, token, raw = false, updated_since = nil)
    github_api_url = get_github_api_url
    get_json("#{github_api_url}/repos/#{repo_fullname}", token, raw, updated_since)
  end

  def self.repo_tags(repository, token)
    github_api_url = get_github_api_url
    get_json("#{github_api_url}/repos/#{repository}/tags", token)
  end

  def self.repo_tags_all(repository, token)
    tags = []
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repository}/tags"
    begin
      request_headers = build_request_headers token
      response = get(url, headers: request_headers)
      content  = JSON.parse( response.body, symbolize_names: true )
      data     = catch_github_exception( content )
      tags     += data if data
      paging   = paging_for response
      url      = paging[:paging]["next"]
    end while not url.nil?
    tags = nil if tags.empty?
    tags
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.read_repo_data repo, token, try_n = 3
    return nil if repo.nil?

    self.update_branches repo, token
    self.update_project_files repo, token, try_n
  end

  def self.update_project_files repo, token, try_n = 3
    project_files = nil
    repo = repo.deep_symbolize_keys if repo.respond_to? "deep_symbolize_keys"
    fullname = repo[:full_name]
    fullname = repo[:fullname] if fullname.to_s.empty?

    # Adds project files
    try_n.times do
      project_files = repo_project_files(fullname, token, nil)
      break unless project_files.nil? or project_files.empty?
      log.info "Trying to read `#{fullname}` again"
      sleep 3
    end

    if project_files.nil?
      msg = "Cant read project files for repo `#{fullname}`. Tried to read #{try_n} ntimes."
      log.error msg
    end

    repo[:project_files] = project_files
    repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    repo
  end

  def self.update_branches repo, token
    repo = repo.deep_symbolize_keys if repo.respond_to? "deep_symbolize_keys"
    fullname = repo[:full_name]
    fullname = repo[:fullname] if fullname.to_s.empty?

    branch_docs = self.repo_branches(fullname, token)
    if branch_docs
      branches = []
      branch_docs.each do |branch|
        branches << branch[:name]
      end

      repo[:branches] = branches
    else
      repo[:branches] = ["master"]
    end
    repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    repo[:branches] = ["master"]
    repo
  end

  def self.persist_repos user, url, page = 1, per_page = 30
    response = get(url, headers: A_DEFAULT_HEADERS)
    content  = JSON.parse(response.body, symbolize_names: true)
    data     = catch_github_exception( content )
    create_or_update_repos user, data
    paging_for response
  end

  def self.create_or_update_repos user, data
    return nil if data.nil? || data.empty?

    data.each do |repo|
      next if repo.nil?

      fullname = repo[:full_name]
      fullname = repo[:fullname] if fullname.to_s.empty?
      next if fullname.to_s.empty?

      GithubRepo.build_or_update user, repo
    end
  end

  def self.paging_for response, page = 1, per_page = 30
    paging = {
      paging: {
        start: page,
        per_page: per_page
      },
      etag: response.headers["etag"],
      ratelimit: {
        limit: response.headers["x-ratelimit-limit"],
        remaining: response.headers["x-ratelimit-remaining"]
      }
    }
    paging_links = parse_paging_links(response.headers)
    paging[:paging].merge! paging_links unless paging_links.nil?
    paging
  end


  def self.repo_branches repo_name, token
    branches = []
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repo_name}/branches"
    begin
      request_headers = build_request_headers token
      response = get(url, headers: request_headers)
      content  = JSON.parse( response.body, symbolize_names: true )
      data     = catch_github_exception( content )
      branches += data if data
      paging   = paging_for response
      url      = paging[:paging]["next"]
    end while not url.nil?
    branches = nil if branches.empty?
    branches
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.repo_branch_info repo_name, branch = "master", token = nil
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repo_name}/branches/#{branch}"
    get_json(url, token)
  end


  def self.fetch_project_file_from_branch repo_name, filename, branch = "master", token = nil, sha = nil
    if sha.to_s.empty?
      sha = fetch_current_sha(repo_name, branch, token)
    end

    file_info = Github.project_file_info( repo_name, filename, sha, token)
    if file_info.nil? || file_info.empty?
      log.error %Q{
        fetch_project_file_from_branch | can't read info about project's file.
        repo: #{repo_name} , filename: `#{filename}` , branch: `#{branch}`, sha: `#{sha}`
      }
      return nil
    end

    file_content = fetch_file(file_info[:url], token)
    return nil if file_content.nil?

    file_info.merge({
      branch: branch,
      content: file_content[:content]
    })
  end


  def self.fetch_current_sha repo_name, branch, token
    branch_info = Github.repo_branch_info repo_name, branch, token
    if branch_info.nil? || branch_info[:commit].nil?
      log.error "fetch_current_sha(..) - can't read branch info for [repo_name: #{repo_name}, branch: #{branch}, token: #{token}]"
      return nil
    end
    branch_info[:commit][:sha]
  end


  # TODO: add tests
  def self.project_file_info(git_project, filename, sha, token)
    github_api_url = get_github_api_url
    url   = "#{github_api_url}/repos/#{git_project}/git/trees/#{sha}?recursive=1"
    tree = get_json(url, token)
    if tree.nil? || !tree.has_key?(:tree)
      log.error "No file tree for #{url}"
      return nil
    end

    matching_files = tree[:tree].keep_if {|blob| blob[:path] == filename}
    if matching_files.nil? or matching_files.empty?
      log.error "No file matches #{filename}"
      return nil
    end

    file = matching_files.first
    {
      name: file[:path],
      url:  file[:url],
      type: ProjectService.type_by_filename(file[:path])
    }
  end


  def self.repo_branch_tree(repo_name, token, branch_sha, recursive = false)
    rec_val = recursive ? 1 : 0
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repo_name}/git/trees/#{branch_sha}?access_token=#{token}&recursive=#{rec_val}"
    response = get(url, headers: A_DEFAULT_HEADERS )
    if response.code != 200
      msg = "Can't fetch repo tree for `#{repo_name}` from #{url}: #{response.code} #{response.body}"
      log.error msg
      return nil
    end
    JSON.parse(response.body, symbolize_names: false)
  end


  def self.project_files_from_branch(repo_name, token, branch_sha, branch = "master", try_n = 3)
    branch_tree = nil

    try_n.times do
      branch_tree = repo_branch_tree(repo_name, token, branch_sha)
      break unless branch_tree.nil?
      log.error "Going to read tree of branch `#{branch}` for #{repo_name} again after little pause."
      sleep 1 # it's required to prevent bombing Github's api after our request got rejected
    end

    if branch_tree.nil? or !branch_tree.has_key?('tree')
      msg = "Can't read tree for repo `#{repo_name}` on branch `#{branch}`."
      log.error msg
      return nil
    end

    project_files = branch_tree['tree'].keep_if {|file| ProjectService.type_by_filename(file['path'].to_s) != nil}
    project_files.each do |file|
      file.deep_symbolize_keys!
      file[:uuid] = SecureRandom.hex
    end

    project_files
  end


  # Returns all project files in the given repos grouped by branches
  def self.repo_project_files(repo_name, token, branch_docs = nil)
    return nil if repo_name.to_s.empty?

    branches = branch_docs ? branch_docs : repo_branches(repo_name, token)

    if branches.nil? or branches.empty?
      msg = "Repo #{repo_name} doesnt have any branches."
      log.error(msg) and return
    end

    project_files = {}
    branches.each do |branch|
      branch_name  = branch[:name]

      branch_key   = encode_db_key(branch_name)
      branch_sha   = branch[:commit][:sha]
      branch_files = project_files_from_branch(repo_name, token, branch_sha)
      project_files[branch_key] = branch_files unless branch_files.nil?
    end

    project_files
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.fetch_file( url, token )
    return nil if url.to_s.empty?

    uri = URI(url)
    get_json(uri.path, token)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.orga_names( github_token )
    github_api_url = get_github_api_url
    url = "#{github_api_url}/user/orgs?access_token=#{github_token}"
    response = get(url, :headers => A_DEFAULT_HEADERS )
    organisations = catch_github_exception JSON.parse(response.body, symbolize_names: true )
    names = Array.new
    return names if organisations.nil? || organisations.empty?

    names = organisations.map {|x| x[:login]}
    names
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    []
  end


  def self.private_repo?( github_token, name )
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{name}?access_token=#{github_token}"
    response = get(url, :headers => A_DEFAULT_HEADERS )
    repo = catch_github_exception JSON.parse(response.body)
    return repo['private'] unless repo.nil? and !repo.is_a?(Hash)
    false
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.repo_sha(repository, token)
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repository}/git/refs/heads"
    heads = get_json(url, token)

    heads.to_a.each do |head|
      return head[:object][:sha] if head[:url].match(/heads\/master\z/)
    end
    nil
  end


  def self.create_webhook repo, token, body_hash
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repo}/hooks"
    post_json url, body_hash, token
  end

  def self.update_status repo, sha, token, body_hash
    github_api_url = get_github_api_url
    url = "#{github_api_url}/repos/#{repo}/statuses/#{sha}"
    post_json url, body_hash, token
  end


  def self.get_json(url, token = nil, raw = false, updated_at = nil)
    request_headers = build_request_headers token, updated_at
    response = get(url, headers: request_headers)
    return response if raw

    content = JSON.parse(response.body, symbolize_names: true)
    catch_github_exception( content )
  rescue => e
    log.error "ERROR in get_json( #{url} ) error message: #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end


  def self.post_json( url, body_hash, token, raw = false, updated_at = nil )
    request_headers = build_request_headers token, updated_at
    response = post(url, body: body_hash.to_json, headers: request_headers)
    return response if raw

    content = JSON.parse(response.body, symbolize_names: true)
    catch_github_exception( content )
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


  def self.encode_db_key(key_val)
    URI.escape(key_val.to_s, /\.|\$/)
  end

  def self.decode_db_key(key_val)
    URI.unescape key_val.to_s
  end


  private

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
      else
        return data
      end
    rescue => e
      # by default here should be no message or nil
      # We expect that everything is ok and there is no error message
      log.error e.message
      log.error e.backtrace.join("\n")
      nil
    end

    def self.parse_paging_links( headers )
      return nil unless headers.has_key? "link"

      links = []
      headers["link"].split(",").each do |link_token|
        matches = link_token.strip.match /<([\w|\/|\.|:|=|?|\&]+)>;\s+rel=\"(\w+)\"/m
        links << [matches[2], matches[1]]
      end
      Hash[*links.flatten]
    end

end

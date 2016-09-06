require 'oauth'

class Stash < Versioneye::Service

  A_API_V1_PATH = "/rest/api/1.0"
  A_DEFAULT_HEADERS = {"User-Agent" => "Chrome28 (contact@versioneye.com)"}


  def self.consumer_key
   Settings.instance.stash_consumer_key
  end


  def self.init_oauth_client
    private_rsa_key = Settings.instance.stash_private_rsa
    OAuth::Consumer.new(
      consumer_key,
      OpenSSL::PKey::RSA.new( private_rsa_key ),
      {
      :site => Settings.instance.stash_base_url,
      :signature_method => 'RSA-SHA1',
      :scheme => :header,
      :http_method => :post,
      :request_token_path=> '/plugins/servlet/oauth/request-token',
      :access_token_path => '/plugins/servlet/oauth/access-token',
      :authorize_path => '/plugins/servlet/oauth/authorize'
    })
  end


  def self.request_token(callback_url)
    consumer = init_oauth_client()
    request_token = consumer.get_request_token(:oauth_callback => callback_url)
    request_token
  end


  # Returns user information for authorized user
  def self.user(token, secret)
    path = "/plugins/servlet/applinks/whoami"
    username = get_json(path, token, secret, true)

    path = "#{A_API_V1_PATH}/users/#{username}"
    response = get_json(path, token, secret)

    response
  end


  def self.projects_all( token, secret, per_page = 100 )
    projects = []
    start = 0
    limit = per_page
    response = {}
    response[:isLastPage] = false
    while response[:isLastPage] == false
      response = Stash.projects(token, secret, start, limit)
      break if response.nil?

      projects << response[:values]
      start += per_page
      limit += per_page
    end
    projects.flatten
  end


  def self.projects( token, secret, start = 0, limit = 1000 )
    path = "#{A_API_V1_PATH}/projects?start=#{start}&limit=#{limit}"
    get_json(path, token, secret)
  end


  def self.all_repos( token, secret )
    repos = []
    projects = self.projects_all( token, secret )
    projects.each do |project|
      reps = project_repos( project[:key], token, secret )
      repos << reps[:values] if reps[:values] && !reps[:values].empty?
    end
    repos.flatten
  end


  def self.project_repos( projectKey, token, secret, start = 0, limit = 1000 )
    path = "#{A_API_V1_PATH}/projects/#{projectKey}/repos?start=#{start}&limit=#{limit}"
    get_json(path, token, secret)
  end


  def self.branches( projectKey, repo, token, secret, start = 0, limit = 1000  )
    path = "#{A_API_V1_PATH}/projects/#{projectKey}/repos/#{repo}/branches?start=#{start}&limit=#{limit}"
    get_json(path, token, secret)
  end

  def self.branch_names( projectKey, repo, token, secret )
    names = []
    path = "#{A_API_V1_PATH}/projects/#{projectKey}/repos/#{repo}/branches?start=0&limit=10000"
    response = get_json(path, token, secret)
    response[:values].each do |branch|
       names << branch[:displayId]
    end
    names
  end


  def self.files( projectKey, repo, branch = 'master', token = '', secret = '', limit = '100000' )
    path = "#{A_API_V1_PATH}/projects/#{projectKey}/repos/#{repo}/files?at=#{branch}&start=0&limit=#{limit}"
    get_json(path, token, secret)
  end


  # path = Path to file. For example "Gemfile"
  # revision = "refs/heads/<BRANCH>" -> "refs/heads/feature/nine"
  def self.content( projectKey, repo, path, revision, token, secret )
    path = "#{A_API_V1_PATH}/projects/#{projectKey}/repos/#{repo}/browse/#{path}?at=#{revision}"
    get_json(path, token, secret)
  end


  def self.get_json(path, token, secret, raw = false, params = {}, headers = {})
    url = "#{Settings.instance.stash_base_url}#{path}"
    oauth = init_oauth_client
    oauth_token = OAuth::AccessToken.new(oauth, token, secret)
    oauth_params = {consumer: oauth, token: oauth_token, request_uri: url}
    request_headers = A_DEFAULT_HEADERS
    request_headers.merge! headers

    response = oauth_token.get(path, request_headers)
    if raw == true
      return response.body
    end

    begin
      JSON.parse(response.body, symbolize_names: true)
    rescue => e
      log.error "Got status: #{response.code} #{response.message} body: #{response.body}"
      log.error e.message
      log.error e.backtrace.join("\n")
      nil
    end
  rescue => e
    log.error "Fuck up in get_json - #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end


  def self.encode_db_key(key_val)
    URI.escape(key_val.to_s, /\.|\$/)
  end

  def self.decode_db_key(key_val)
    URI.unescape key_val.to_s
  end


end

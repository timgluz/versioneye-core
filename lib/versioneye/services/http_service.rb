class HttpService < Versioneye::Service

  def self.fetch_response url, timeout = 60

    env = Settings.instance.environment
    proxy_addr = GlobalSetting.get env, 'proxy_addr'
    proxy_port = GlobalSetting.get env, 'proxy_port'
    proxy_user = GlobalSetting.get env, 'proxy_user'
    proxy_pass = GlobalSetting.get env, 'proxy_pass'

    uri  = URI.parse url
    http = nil

    if proxy_addr.to_s.empty?
      http = Net::HTTP.new uri.host, uri.port
    elsif !proxy_addr.to_s.empty? && !proxy_user.to_s.empty? && !proxy_pass.to_s.empty?
      http = Net::HTTP.new uri.host, uri.port, proxy_addr, proxy_port, proxy_user, proxy_pass
    elsif !proxy_addr.to_s.empty? && proxy_user.to_s.empty?
      http = Net::HTTP.new uri.host, uri.port, proxy_addr, proxy_port
    end

    http.read_timeout = timeout # in seconds
    if uri.port == 443
      http.use_ssl = true
    end
    path  = uri.path
    query = uri.query
    http.get("#{path}?#{query}")
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

end

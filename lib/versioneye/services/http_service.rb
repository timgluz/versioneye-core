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
    elsif !proxy_addr.to_s.empty? && !proxy_port.to_s.empty? && !proxy_user.to_s.empty? && !proxy_pass.to_s.empty?
      http = Net::HTTP.new uri.host, uri.port, proxy_addr, proxy_port.to_i, proxy_user, proxy_pass
    elsif !proxy_addr.to_s.empty? && !proxy_port.to_s.empty? && proxy_user.to_s.empty?
      http = Net::HTTP.new uri.host, uri.port, proxy_addr, proxy_port.to_i
    end

    http.read_timeout = timeout # in seconds
    if uri.port == 443
      http.use_ssl = true
    end
    path  = uri.path.to_s
    path  = '/' if path.to_s.empty?
    query = uri.query.to_s

    req = nil
    if query.to_s.empty?
      req = Net::HTTP::Get.new("#{path}", {'User-Agent' => 'https://www.VersionEye.com - https://twitter.com/VersionEye'})
    else
      req = Net::HTTP::Get.new("#{path}?#{query}", {'User-Agent' => 'https://www.VersionEye.com - https://twitter.com/VersionEye'})
    end
    http.request(req)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

end

class HttpService < Versioneye::Service

  def self.fetch_response url, timeout = 60
    uri  = URI.parse url
    http = Net::HTTP.new uri.host, uri.port
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

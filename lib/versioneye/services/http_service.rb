class HttpService < Versioneye::Service

  def self.fetch_response url, timeout = 60
    uri  = URI.parse url
    http = Net::HTTP.new uri.host, uri.port
    http.read_timeout = timeout # in seconds 
    if uri.port == 443
      curl_ca_bundle  = '/opt/local/share/curl/curl-ca-bundle.crt'
      ca_certificates = '/usr/lib/ssl/certs/ca-certificates.crt'
      http.use_ssl = true
      if File.exist?(curl_ca_bundle)
        http.ca_file = curl_ca_bundle
      elsif File.exist?(ca_certificates)
        http.ca_file = ca_certificates
      end
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

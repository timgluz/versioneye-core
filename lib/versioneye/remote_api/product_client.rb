class ProductClient < Versioneye::Service


  A_API = 'https://www.versioneye.com/api'
  A_API_VERSION = '/v2'
  A_API_ENDPOINT_PRODUCT = '/products'


  def self.show language, prod_key, version = nil
    return nil if language.to_s.empty? || prod_key.to_s.empty?

    encoded_prod_key = encode prod_key
    url = "#{A_API}#{A_API_VERSION}#{A_API_ENDPOINT_PRODUCT}/#{language}/#{encoded_prod_key}"
    if version
      url += "?prod_version=#{version}"
    end
    json = fetch_json url
  end


  def self.versions language, prod_key
    return nil if language.to_s.empty? || prod_key.to_s.empty?

    encoded_prod_key = encode prod_key
    url = "#{A_API}#{A_API_VERSION}#{A_API_ENDPOINT_PRODUCT}/#{language}/#{encoded_prod_key}/versions"
    json = fetch_json url
  end


  private

    def self.fetch_json url
      JSON.parse CommonParser.new.fetch_response_body( url )
    rescue => e
      err_msg = "ERROR with #{url} .. #{e.message} "
      p err_msg
      log.error err_msg
      nil
    end

    def self.encode value
      value.gsub("/", ":").gsub(".", "~")
    end

end

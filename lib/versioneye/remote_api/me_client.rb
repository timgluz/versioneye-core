class MeClient < Versioneye::Service


  A_API = 'https://www.versioneye.com/api'
  A_API_VERSION = '/v2'
  A_API_ENDPOINT_PRODUCT = '/me'


  def self.show api_key
    return nil if api_key.to_s.empty?

    url = "#{A_API}#{A_API_VERSION}#{A_API_ENDPOINT_PRODUCT}?api_key=#{api_key}"
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

end

class CommonClient < Versioneye::Service


  A_API = 'https://www.versioneye.com/api'
  A_API_VERSION = '/v2'


  private

    def self.fetch_json url
      JSON.parse CommonParser.new.fetch_response_body( url )
    rescue => e
      p "ERROR with #{url} .. #{e.message} "
      log.error "ERROR with #{url} .. #{e.message} "
      nil
    end

    def self.encode value
      value.gsub("/", ":").gsub(".", "~")
    end

    def self.encod_language language
      language.gsub('.', '')
    end

end

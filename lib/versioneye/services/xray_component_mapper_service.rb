class XrayComponentMapperService < Versioneye::Service


  def self.get_hash component_id, base_url = "http://server-xray:8000/api/v1/componentMapper"
    component_id = component_id.gsub('//', '/')
    url = "#{base_url}/#{component_id}"
    response_body = CommonParser.new.fetch_response_body( url )
    log.info "url #{url} returns response_body: #{response_body}"
    JSON.parse response_body
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  # gav://commons-beanutils:commons-beanutils:1.9.1
  def self.get_component_id product, version
    return nil if product.nil?
    return nil if version.nil?

    if product.prod_type.eql?(Project::A_TYPE_MAVEN2) ||
       product.prod_type.eql?(Project::A_TYPE_SBT) ||
       product.prod_type.eql?(Project::A_TYPE_GRADLE) ||
       product.prod_type.eql?(Project::A_TYPE_LEIN) ||
       product.language.to_s.eql?(Product::A_LANGUAGE_JAVA)
      return "gav://#{product.group_id}:#{product.artifact_id}:#{version.to_s}"
    elsif product.prod_type.eql?(Project::A_TYPE_RUBYGEMS)
      return "gem://#{product.prod_key}:#{version.to_s}"
    elsif product.prod_type.eql?(Project::A_TYPE_COMPOSER)
      return "com://#{product.prod_key.to_s.gsub('/', ':')}:#{version.to_s}"
    elsif product.prod_type.eql?(Project::A_TYPE_NPM)
      return "npm://#{product.prod_key}:#{version.to_s}"
    elsif product.prod_type.eql?(Project::A_TYPE_PIP)
      return "pip://#{product.prod_key}:#{version.to_s}"
    end
    nil
  end


end

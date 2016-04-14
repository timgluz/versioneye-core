class XrayComponentMapperService < Versioneye::Service


  def self.get_hash component_id, base_url = "http://10.50.1.35:8000/api/v1/componentMapper"
    component_id = component_id.gsub('//', '/')
    url = "#{base_url}/#{component_id}"
    u   = URI::encode(url)
    JSON.parse CommonParser.new.fetch_response_body( u )
  end


  # gav://commons-beanutils:commons-beanutils:1.9.1
  def self.get_component_id product, version
    return nil if product.nil?
    return nil if product.group_id.to_s.empty?
    return nil if product.artifact_id.to_s.empty?
    return nil if version.nil?

    if product.prod_type.eql?(Project::A_TYPE_MAVEN2) ||
       product.prod_type.eql?(Project::A_TYPE_SBT) ||
       product.prod_type.eql?(Project::A_TYPE_GRADLE) ||
       product.prod_type.eql?(Project::A_TYPE_LEIN)
       return "gav://#{product.group_id}:#{product.artifact_id}:#{version.to_s}"
    end
    nil
  end


end

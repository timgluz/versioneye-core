class XrayService < Versioneye::Service

  # Handle new security vulnerability
  # svjson has to be the values
  #
  # - [language, prod_key, name_id, affected_versions]
  #
  def self.handle_new_sv svjson
    env = Settings.instance.environment
    return nil if env.to_s.eql?("production")
    # Return nil on production. This method should
    # only be called on enterprise and test environments.

    language = svjson[:language]
    prod_key = svjson[:prod_key]
    product = Product.new({:language => language, :prod_key => prod_key})
    if language.eql?( Product::A_LANGUAGE_JAVA )
      group_id = prod_key.split("/")[0]
      artifact_id = prod_key.split("/")[1]
      product.group_id = group_id
      product.artifact_id = artifact_id
      product.prod_type = Project::A_TYPE_MAVEN2
    end
    svjson[:affected_versions].each do |version|
      p " XrayService.handle_new_sv for #{language}:#{prod_key}:#{version.to_s}"
      log.info " XrayService.handle_new_sv for #{language}:#{prod_key}:#{version.to_s}"
      comp_id = XrayComponentMapperService.get_component_id product, version.to_s.strip
      hash    = XrayComponentMapperService.get_hash comp_id
      next if hash.nil?

      triggerDeepScan product, version, svjson[:name_id], hash["Blobs"].first
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.triggerDeepScan product, version, sv_name_id, blob_hash
    xst = XrayScanTrigger.new({:language => product.language,
      :prod_key => product.prod_key, :version => version.to_s.strip,
      :sv_name_id => sv_name_id, :hash => blob_hash })
    xst.save
    url = 'http://server-xray:8000/api/v1/excludedFeed'
    json_hash = {"correlationId" => xst.ids, "vulnerableBlobs" => [blob_hash]}
    HttpService.post_json url, json_hash
  end


end

# VersioneyeCore.new
# sv = SecurityVulnerability.where(:language => "Java", :prod_key => "commons-beanutils/commons-beanutils").first
# svjson = {:language => sv.language, :prod_key => sv.prod_key, :affected_versions => ["1.7.0", "1.0", "1.2", "1.3", "1.4", "1.4.1", "1.5", "1.6", "1.6.1", "1.8.0", "1.8.0-BETA", "1.8.1", "1.8.2", "1.8.3", "20020520", "20021128.082114", "20030211.134440", "1.7.0clean-brew", "1.9.0", "1.9.1"], :name_id => sv.name_id}
# XrayService.handle_new_sv svjson
# "1.7.0", "1.0", "1.2", "1.3", "1.4", "1.4.1", "1.5", "1.6", "1.6.1", "1.8.0", "1.8.0-BETA", "1.8.1", "1.8.2", "1.8.3", "20020520", "20021128.082114", "20030211.134440", "1.7.0clean-brew", "1.9.0", "1.9.1"

# comp_id = "gav://commons-beanutils:commons-beanutils:1.9.1"

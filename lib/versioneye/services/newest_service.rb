class NewestService < Versioneye::Service


  def self.run_worker
    loop do 
      post_process
      multi_log "sleep for a while"
      sleep 60
    end
  end


  def self.post_process
    newests = Newest.any_of( {:processed => false}, {:processed => nil} )
    newests.each do |newest| 
      process newest 
    end
  end

  
  def self.process newest 
    product = newest.product 
    return nil if product.nil? 

    multi_log "---"
    multi_log "update_meta_data for #{product.language}:#{product.prod_key}"
    ProductService.update_meta_data product, false 

    multi_log "update_dependencies for #{product.language}:#{product.prod_key}"
    update_dependencies product, newest.version

    newest.processed = true 
    newest.save 
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_dependencies product, version
    if product.prod_type.eql?(Project::A_TYPE_MAVEN2)
      update_current_version_maven product
      update_outdated_maven( product )
    else 
      update_current_version( product ) 
      update_outdated( product ) 
    end
    multi_log "update product dependencies for #{product.language}:#{product.prod_key}:#{version}"
    DependencyService.update_dependencies product, version
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  
  def self.update_current_version_maven product 
    multi_log "update_current_version_maven for #{product.language}:#{product.prod_key}"
    Dependency.where(
      :group_id => product.group_id, 
      :artifact_id => product.artifact_id
      ).update_all(:current_version => product.version)
  end

  
  def self.update_current_version product 
    multi_log "update_current_version for #{product.language}:#{product.prod_key}"
    Dependency.where(
      :language => product.language, 
      :dep_prod_key => product.prod_key
      ).update_all(:current_version => product.version)
  end


  def self.update_outdated_maven product 
    multi_log "update_outdated_maven for #{product.language}:#{product.prod_key}"
    dependencies = Dependency.where(
      :group_id => product.group_id, 
      :artifact_id => product.artifact_id)
    dependencies.each do |dependency|
      DependencyService.soft_outdated?( dependency, product )
    end
  end


  def self.update_outdated product 
    multi_log "update_outdated for #{product.language}:#{product.prod_key}"
    dependencies = Dependency.where(
      :language => product.language, 
      :dep_prod_key => product.prod_key)
    dependencies.each do |dependency|
      DependencyService.soft_outdated?( dependency, product )
    end
  end


  private 


    def self.multi_log msg 
      p msg 
      log.info msg 
    end


end

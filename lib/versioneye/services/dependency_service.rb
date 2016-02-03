class DependencyService < Versioneye::Service

  A_DAY = 86400 # 86400 seconds = 24 hours
  A_FIVE_DAYS = 432000
  A_DEPENDENCY_TTL = 432000


  def self.dependencies_outdated?( dependencies, cached = false )
    return false if dependencies.nil? || dependencies.empty?

    dependencies.each do |dependency|
      outdated = out_of_date?( dependency, cached )
      return true if outdated == true
    end
    false
  end


  def self.out_of_date?( dependency, cached = true )
    return self.cache_outdated?( dependency ) if cached == true
    return self.outdated?( dependency )       if cached == false
  end


  def self.cache_outdated?( dependency )
    key = "#{dependency.id.to_s}_outdated?"
    outdated = cache.get( key )
    return outdated if !outdated.nil?

    outdated = self.outdated?( dependency )
    cache.set( key, outdated, A_DEPENDENCY_TTL )
    outdated
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    false
  end


  def self.outdated?( dependency, update_newest_version = true )
    product = dependency.product
    return false if product.nil?

    if product.versions.nil? || product.versions.empty?
      dependency.outdated = false
      dependency.current_version = '0.0.0+NA'
      dependency.save
      return false
    end

    newest_product_version = product.version
    if update_newest_version
      newest_product_version = VersionService.newest_version_number( product.versions )
    end
    dependency.current_version = newest_product_version

    soft_outdated?( dependency, product )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.soft_outdated?( dependency, product = nil )
    product = dependency.product if product.nil?
    newest_product_version = dependency.current_version
    self.update_parsed_version( dependency, product )
    parsed_version = dependency.parsed_version
    if newest_product_version.eql?(parsed_version) || VersionService.equal(newest_product_version, parsed_version)
      dependency.outdated = false
      dependency.save
      return false
    end

    # This is for the case that the parsed version is higher than our newest version in the database!
    newest_version = Naturalsorter::Sorter.sort_version([dependency.parsed_version, newest_product_version]).last
    if VersionService.equal(newest_version, parsed_version)
      dependency.outdated = false
      dependency.save
      return false
    end

    dependency.outdated = true
    dependency.save
    return true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.update_parsed_version dependency, product = nil
    if product.nil?
      product  = find_product( dependency.prod_type, dependency.language, dependency.dep_prod_key )
    end

    if ( dependency.version.to_s.empty? || dependency.version.to_s.eql?("*") ) && product
      dependency.parsed_version = product.version
      return
    end

    dependency.set_prod_type_if_nil
    parser   = ParserStrategy.parser_for( dependency.prod_type, '' )
    if parser.nil?
      log.error "No parser found for #{dependency.prod_type}"
      return nil
    end
    proj_dep = Projectdependency.new
    parser.parse_requested_version( dependency.version, proj_dep, product )
    dependency.parsed_version = proj_dep.version_requested
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return nil
  end


  def self.find_product prod_type, language, dep_prod_key
    if dep_prod_key.eql?("php/php") or dep_prod_key.eql?("php")
      language = Product::A_LANGUAGE_C
    end
    if prod_type.eql?(Project::A_TYPE_BOWER)
      return Product.fetch_bower dep_prod_key
    end
    Product.fetch_product( language, dep_prod_key )
  end


  def self.update_dependencies_global()
    all_dependencies_paged do |dependencies|
      update_dependencies_for( dependencies )
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  # This method updates the dependencies of a product.
  # It updates the parsed_version and the outdated field.
  def self.update_dependencies( product, version = nil )
    deps = product.all_dependencies( version )
    return if deps.nil? || deps.empty?

    update_dependencies_for deps
    product.update_attribute(:dep_count, deps.count)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_dependencies_for deps
    deps.each do |dependency|
      cache_outdated?( dependency )
    end
  end


  def self.all_dependencies_paged
    count = Dependency.count()
    page = 1000
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      dependencies = Dependency.all().skip(skip).limit(page)

      yield dependencies

      co = i * page
      log_msg = "all_dependencies_paged iteration: #{i} - dependencies processed: #{co}"
      p log_msg
      log.info log_msg
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end

class DependencyService < Versioneye::Service

  A_DEPENDENCY_TTL = 86400 # 86400 seconds = 24 hours

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


  def self.outdated?( dependency )
    product = dependency.product
    return false if product.nil?

    newest_product_version = VersionService.newest_version_number( product.versions )
    dependency.current_version = newest_product_version
    self.update_parsed_version( dependency, product )
    dependency.save

    return false if newest_product_version.eql?( dependency.parsed_version )

    newest_version = Naturalsorter::Sorter.sort_version([dependency.parsed_version, newest_product_version]).last
    return false if newest_version.eql?( dependency.parsed_version )

    return true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end


  def self.update_parsed_version dependency, product = nil
    if dependency.version.to_s.empty?
      dependency.parsed_version = "unknown"
      return
    end

    if product.nil?
      product  = find_product( dependency.prod_type, dependency.language, dependency.dep_prod_key )
    end
    dependency.set_prod_type_if_nil
    parser   = ParserStrategy.parser_for( dependency.prod_type, '' )
    proj_dep = Projectdependency.new
    parser.parse_requested_version( dependency.version, proj_dep, product )
    dependency.parsed_version = proj_dep.version_requested
  end


  private


    def self.find_product prod_type, language, dep_prod_key
      if dep_prod_key.eql?("php/php") or dep_prod_key.eql?("php")
        language = Product::A_LANGUAGE_C
      end
      if prod_type.eql?(Project::A_TYPE_BOWER)
        return Product.fetch_bower dep_prod_key
      else
        return Product.fetch_product( language, dep_prod_key )
      end
    end

end

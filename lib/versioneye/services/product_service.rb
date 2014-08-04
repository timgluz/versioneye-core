class ProductService < Versioneye::Service


  # languages have to be an array of strings.
  def self.search(q, group_id = nil, languages = nil, page_count = 1)
    EsProduct.search(q, group_id, languages, page_count)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    MongoProduct.find_by(q, '', group_id, languages, 300).paginate(:page => page_count)
  end


  # This method fetches and product and initializes it for the UI.
  def self.fetch_product( lang, prod_key, version = nil )
    product = Product.fetch_product lang, prod_key
    if product.nil? && lang.eql?( Product::A_LANGUAGE_CLOJURE )
      product = Product.fetch_product Product::A_LANGUAGE_JAVA, prod_key
    end
    return nil if product.nil?

    product.check_nil_version
    product.version = version if version

    if !lang.eql?( Product::A_LANGUAGE_JAVA )
      update_dependencies( product )
    end

    update_average_release_time( product )
    product
  end


  def self.update_dependencies_global()
    count = Product.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      products = Product.all().skip(skip).limit(page)
      update_deps products
      co = i * page
      log_msg = "update_dependencies_global iteration: #{i} - products processed: #{co}"
      p log_msg
      log.info log_msg
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  # This method updates the dependencies of a product.
  # It updates the parsed_version and the outdated field.
  def self.update_dependencies( product )
    deps = product.all_dependencies
    return if deps.nil? || deps.empty?

    deps.each do |dependency|
      dependency.outdated = DependencyService.cache_outdated?( dependency )
      dependency.save
    end
    product.dep_count = deps.count
    product.save
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_average_release_time product
    average_release_time = VersionService.average_release_time( product.versions )
    if average_release_time.nil?
      average_release_time = VersionService.estimated_average_release_time( product.versions )
    end
    product[:average_release_time] = average_release_time
  end


  def self.follow language, prod_key, user
    result = false
    product = Product.fetch_product language, prod_key
    product.users = Array.new if product && product.users.nil?
    if product && user && !product.users.include?( user )
      product.users.push user
      product.followers = 0 if product.followers.nil?
      product.followers += 1
      result = product.save
    end
    result
  end


  def self.unfollow language, prod_key, user
    result = false
    product = Product.fetch_product language, prod_key
    product.users = Array.new if product && product.users.nil?
    if product && user && product.users.include?( user )
      product.users.delete(user)
      product.followers = 0 if product.followers.nil?
      product.followers -= 1
      result = product.save
    end
    result
  end


  # Updates product.version with the newest version number from product.versions
  def self.update_version_data( product, persist = true )
    return nil if product.nil?

    versions = product.versions
    return nil if versions.nil? || versions.empty?

    newest_stable_version = VersionService.newest_version( versions )
    return nil if newest_stable_version.to_s.eql?( product.version)

    product.version = newest_stable_version.to_s
    product.save if persist
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_meta_data_global
    count = Product.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      products = Product.all().skip(skip).limit(page)
      update_products products
      co = i * page
      log_msg = "update_meta_data_global iteration: #{i} - products processed: #{co}"
      p log_msg
      log.info log_msg
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.update_used_by_count product, persist = true
    prod_keys = Dependency.where(:language => product.language, :dep_prod_key => product.prod_key).distinct(:prod_key)
    count = prod_keys.count
    return nil if count == product.used_by_count

    reference = Reference.find_or_create_by(:language => product.language, :prod_key => product.prod_key )
    reference.update_from prod_keys
    reference.save

    product.used_by_count = count
    product.save if persist
  end


  def self.update_followers
    products = Product.where( :'user_ids.0' => {'$exists' => true} )
    products.each do |product|
      self.update_followers_for product
    end
  end


  def self.update_followers_for product
    return nil if product.followers == product.user_ids.count

    product.followers = product.user_ids.count
    product.save
  end


  def self.remove product
    EsProduct.remove( product )
    product.remove
  end


  def self.most_referenced(language, page)
    Product.by_language( language ).desc(:used_by_count).paginate(:page => page)
  end


  private


    def self.update_products products
      products.each do |product|
        p " -- update #{product.language} - #{product.prod_key}"
        self.update_version_data  product, true
        self.update_followers_for product
        self.update_used_by_count product, true
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end

    def self.update_deps products
      products.each do |product|
        p " -- update dependencies for #{product.language} - #{product.prod_key}"
        self.update_dependencies product
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end

end

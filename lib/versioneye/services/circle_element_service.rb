class CircleElementService < Versioneye::Service


  # TODO refactor usage
  def self.dependency_circle(lang, prod_key, version, scope)
    if scope == nil
      scope = Dependency.main_scope( lang )
    end
    hash = Hash.new
    dependencies = Array.new
    if scope.eql?('all')
      dependencies = Dependency.find_by_lang_key_and_version( lang, prod_key, version )
    else
      dependencies = Dependency.find_by_lang_key_version_scope( lang, prod_key, version, scope )
    end
    dependencies.each do |dep|
      next if dep.name.nil? || dep.name.empty?
      DependencyService.update_parsed_version( dep ) if dep.parsed_version.nil?
      element = CircleElement.new
      element.init_arrays
      element.dep_prod_key = dep.dep_prod_key
      element.version      = dep.parsed_version
      element.level        = 0
      self.attach_label_to_element(element, dep)
      hash[dep.dep_prod_key] = element
    end
    return self.fetch_deps(1, hash, Hash.new, lang)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.fetch_deps(deep, hash, parent_hash, lang)
    return hash if hash.empty?
    new_hash = Hash.new
    hash.each do |prod_key, element|
      product = Product.find_by_lang_key( lang, prod_key )
      if product.nil?
        next
      end
      valid_version = ( element.version && !element.version.eql?("") && !element.version.eql?("0") && product.version_by_number( element.version ) )
      product.version = element.version if valid_version
      dependencies = product.dependencies(nil)
      dependencies.each do |dep|
        if dep.name.nil? || dep.name.empty?
          next
        end
        DependencyService.update_parsed_version( dep ) if dep.parsed_version.nil?
        key = dep.dep_prod_key
        ele = self.get_element_from_hash(new_hash, hash, parent_hash, key)
        if ele
          ele.connections << "#{element.dep_prod_key}"
        else
          new_element = CircleElement.new
          new_element.init_arrays
          new_element.dep_prod_key   = dep.dep_prod_key
          new_element.level          = deep
          attach_label_to_element(new_element, dep)
          new_element.connections    << "#{element.dep_prod_key}"
          new_element.version        = dep.parsed_version
          new_hash[dep.dep_prod_key] = new_element
        end
        element.connections  << "#{key}"
        element.dependencies << "#{key}"
      end
    end
    parent_merged = hash.merge(parent_hash)
    deep += 1
    rec_hash = self.fetch_deps(deep, new_hash, parent_merged, lang)
    merged_hash = parent_merged.merge(rec_hash)
    return merged_hash
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.generate_json_for_circle_from_hash(circle)
    resp = ""
    circle.each do |key, dep|
      resp += "{"
      resp += "\"connections\": [#{dep.connections_as_string}],"
      resp += "\"dependencies\": [#{dep.dependencies_as_string}],"
      resp += "\"text\": \"#{dep.text}\","
      resp += "\"id\": \"#{dep.dep_prod_key}\","
      resp += "\"version\": \"#{dep.version}\""
      resp += "},"
    end
    end_point = resp.length - 2
    resp = resp[0..end_point]
    resp
  end

  def self.generate_json_for_circle_from_array(circle)
    resp = ""
    circle.each do |element|
      resp += "{"
      resp += "\"connections\": [#{element.connections_string}],"
      resp += "\"dependencies\": [#{element.dependencies_string}],"
      resp += "\"text\": \"#{element.text}\","
      resp += "\"id\": \"#{element.dep_prod_key}\","
      resp += "\"version\": \"#{element.version}\""
      resp += "},"
    end
    end_point = resp.length - 2
    resp = resp[0..end_point]
    resp
  end


  private


    def self.attach_label_to_element(element, dep)
      return nil if !element or !dep
      element.text = "#{dep.name}:#{dep.version}"
    end

    def self.get_element_from_hash(new_hash, hash, parent_hash, key)
      element = new_hash[key]
      return element if !element.nil?
      element = hash[key]
      return element if !element.nil?
      element = parent_hash[key]
      return element
    end

end

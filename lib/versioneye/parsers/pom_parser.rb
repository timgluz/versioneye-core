require 'versioneye/parsers/common_parser'

class PomParser < CommonParser

  # Parser for pom.xml file from Maven2/Maven3. Java.
  # XPath: //project/dependencyManagement/dependencies/dependency
  # XPath: //project/dependencies/dependency
  #
  def parse( url )
    response = self.fetch_response( url )
    parse_content response.body
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def parse_content( content )
    doc        = fetch_xml( content )
    project    = init_project( doc )
    properties = fetch_properties( doc )
    doc.xpath('//dependencies/dependency').each do |node|
      fetch_dependency(node, properties, project)
    end
    doc.xpath('//plugins/plugin').each do |node|
      dep = fetch_dependency(node, properties, project, "plugin")
    end
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def fetch_dependency(node, properties, project, scope = Dependency::A_SCOPE_COMPILE)
    dependency = Projectdependency.new
    dependency.language = Product::A_LANGUAGE_JAVA
    dependency.scope = scope
    node.children.each do |child|
      if child.name.casecmp('groupId') == 0
        groupId_text = get_variable_value_from_pom(properties, child.text.strip)
        dependency.group_id = groupId_text.downcase
      elsif child.name.casecmp('artifactId') == 0
        artifactId_text = get_variable_value_from_pom(properties, child.text.strip)
        dependency.artifact_id = artifactId_text.downcase
      elsif child.name.casecmp('version') == 0
        version_text = get_variable_value_from_pom(properties, child.text.strip)
        dependency.version_requested = version_text
      elsif child.name.casecmp('scope') == 0
        scope_text = get_variable_value_from_pom(properties, child.text.strip)
        dependency.scope = scope_text
      end
    end
    dependency.name = dependency.artifact_id
    product = fetch_product dependency
    parse_requested_version( dependency.version_requested, dependency, product )
    dependency.prod_key    = product.prod_key if product
    project.unknown_number += 1 if product.nil?
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.projectdependencies.push( dependency )
    dependency
  end

  def fetch_properties( doc )
    properties = Hash.new
    doc.xpath('//project/properties').each do |node|
      node.children.each do |child|
        unless child.text.strip.empty?
          properties[child.name.downcase] = child.text.strip
        end
      end
    end
    project_version = doc.xpath('//project/version')
    if project_version
      properties['project.version'] = project_version.text.strip
    end
    properties
  end

  def get_variable_value_from_pom( properties, val )
    return val if !val.include?('${') || !val.include?('}')

    value = String.new val
    val.scan(/\$\{([^\}]*)\}/xi).each do |match|
      m_val = match[0]
      replacement = properties[ m_val.downcase ]
      next if replacement.to_s.empty?

      value.gsub!("${#{ m_val }}", replacement)
    end
    value
  end

  def parse_requested_version(version_number, dependency, product)
    if version_number.nil? || version_number.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = String.new(version_number)
    version = version.to_s.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")

    if product.nil?
      dependency.version_requested = version
      dependency.version_label = version

    # TODO implement more cases

    else
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version

    end
  end

  def init_project( doc )
    project              = Project.new
    project.project_type = Project::A_TYPE_MAVEN2
    project.language     = Product::A_LANGUAGE_JAVA
    project.group_id     = doc.xpath('//project/groupId').text
    project.artifact_id  = doc.xpath('//project/artifactId').text
    project.name         = doc.xpath('//project/name').text
    project.name         = doc.xpath('//project/artifactId').text if project.name.to_s.empty?
    project
  end

  def fetch_xml( content )
    doc = Nokogiri::XML( content )
    return nil if doc.nil?

    doc.remove_namespaces!
    return nil if doc.nil?

    doc
  end

  def fetch_product dependency
    product = nil 
    if dependency.group_id.to_s.empty? 
      group_id = 'org.apache.maven.plugins'
      product = Product.find_by_group_and_artifact(group_id, dependency.artifact_id )
      dependency.group_id = group_id if product 
    else 
      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id )  
    end
    product
  end

end

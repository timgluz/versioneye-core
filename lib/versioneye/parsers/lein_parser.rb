require 'versioneye/parsers/common_parser'

class LeinParser < CommonParser

  def parse( url )
    return nil if url.nil?

    response = self.fetch_response(url)
    return nil if response.nil?

    content  = response.body
    return nil if content.nil?

    parse_content(content)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def parse_content(content, token = nil)
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    xml_content = transform_to_xml content

    doc = Nokogiri::HTML(xml_content)
    dep_items = doc.xpath('//div[@attr="dependencies"]')

    deps = {:unknown_number => 0, :out_number => 0, :projectdependencies => []}
    if dep_items && !dep_items.empty?
      dep_items.each do |item|
        self.build_dependencies item.children, deps
      end
    end

    project              = Project.new deps
    project.project_type = Project::A_TYPE_LEIN
    project.language     = Product::A_LANGUAGE_CLOJURE
    project.dep_number   = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def transform_to_xml(content)
    # transform to xml
    content = content.gsub /[\;]+.*/, '' # Remove clojure comments
    content = content.gsub /[\s]+/, ' '  # Replace reduntant whitespaces
    content = content.gsub /\[/, '<div>'
    content = content.gsub /\]/, '</div>'
    content = content.gsub /\{/, '<block>'
    content = content.gsub /\}/, '</block>'
    # add attributes to tags
    while true
      match = content.match(/\:(\S+)[\s]+\<(\w+)\>/)
      break if match.nil?
      content = "#{match.pre_match} <#{match.to_a[2]} attr=\"#{match.to_a[1]}\"> #{match.post_match}"
    end
    '<project>' + content + '</project>'
  end

  def build_dependencies(matches, deps)
    unknowns, out_number = 0, 0
    matches.each do |item|
      next if item.text.to_s.strip.empty? # If dependency element is empty

      _, group_id, name, version = item.text.scan(/((\S+)\/)?(\S+)\s+\"(\S+)\"/)[0]
      next if name.to_s.strip.empty?

      group_id = name if group_id.to_s.empty?
      scope, _ = item.text.scan(/:scope\s+\"(\S+)\"/)[0]
      dependency = Projectdependency.new({
        :scope => scope,
        :group_id => group_id,
        :artifact_id => name,
        :name => name,
        :version_requested => version,
        :version_label => version,
        :comperator => '=',
        :language => Product::A_LANGUAGE_CLOJURE
      })

      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      if product
        dependency.prod_key = product.prod_key
        dependency.version_current = product.version
      else
        deps[:unknown_number] += 1
      end

      if ProjectdependencyService.outdated?( dependency )
        deps[:out_number] += 1
      end

      deps[:projectdependencies] << dependency
    end
  end

  # TODO use this method in this class to parse version strings
  def parse_requested_version(version, dependency, product)
    if version.nil? || version.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
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

end

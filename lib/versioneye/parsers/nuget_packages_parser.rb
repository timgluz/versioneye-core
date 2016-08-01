require 'versioneye/parsers/common_parser'

#Parser for packages.config xml-file
class NugetPackagesParser < NugetParser
  def parse(url)
    response_body = fetch_response_body(url)
    if response_body.nil?
      log.error "Failed to fetch Nuget packages.config from #{url}"
    end

    parse_content(response_body, url)
  end

  def parse_content(response_body, url)
    doc = fetch_xml response_body
    project = init_project(url, doc)
    deps = parse_dependencies(doc)

    parse_dependency_versions(project, deps) #checks outdated versions and attaches each deps to project
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "parse_content: Failed to parse document from #{url}:\n #{response_body}"
    log.error e.backtrace.join('\n')
    nil
  end

  def init_project(url, doc)
    Project.new({
      project_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      url: url,
      name: 'packages.config'
    })
  end

  #reads all the dependencies from the file
  def parse_dependencies(doc)
    deps = []
    pkg_nodes = doc.xpath('//packages/package') 
    return deps if pkg_nodes.nil?

    pkg_nodes.each {|pkg_node| deps << process_dependency(pkg_node) }
  
    deps
  end

  def process_dependency(pkg_node)
    prod_name = pkg_node.attr('id').to_s.strip
    version_requested = pkg_node.attr('version').to_s.strip
    allowed_range = pkg_node.attr('allowedVersions').to_s.strip
    target = pkg_node.attr('targetFramework').to_s.strip

    #by default packages.config fixes automatically version as x >= VERSION, 
    # but allowedVersions allows humans defines acceptable versionRange as in a nuspec;
    version_label = if allowed_range.empty?
                      version_requested
                    else
                      allowed_range
                    end

    Projectdependency.new({
      language: Product::A_LANGUAGE_CSHARP,
      name: prod_name,
      prod_key: prod_name,
      version_label: version_label,
      version_requested: version_label,
      target: target
    })
  end

end

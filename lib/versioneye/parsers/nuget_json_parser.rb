require 'versioneye/parsers/common_parser'

class NugetJsonParser < NugetParser
  def parse( url )
    response_body = fetch_response_body(url)
    if response_body.nil?
      log.error "Failed to fetch Nuget file from #{url}"
      return nil
    end

    parse_content( response_body, url )
  end

  def parse_content(response_body, url)
    doc     = from_json( response_body )
    project = init_project( url, doc )
    deps    = parse_dependencies( doc )

    parse_dependency_versions(project, deps) # attaches parsed dependencies to project
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "ERROR in parse_content(#{response_body}) -> #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end

  def init_project(url, doc)
    project_name = url.to_s.split(/\//).last

    Project.new({
      project_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      url: url,
      name: project_name
    })
  end

  def parse_dependencies(doc)
    deps = []
    doc[:dependencies].each_pair do |prod_name, version_label|
      deps << Projectdependency.new({
        language: Product::A_LANGUAGE_CSHARP,
        name: prod_name.to_s,
        prod_key: prod_name.to_s,
        version_label: version_label,
        version_requested: version_label
      })
    end
    deps
  end


end

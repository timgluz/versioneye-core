require 'versioneye/parsers/package_parser'
require 'semverly'

class JspmParser < PackageParser


  def parse_content(content, token = nil)
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    proj_doc = JSON.parse(content, symbolize_names: true)
    if proj_doc.to_s.empty?
      log.error "Project document is empty - stopping parser"
      return nil
    end

    parse_project_doc proj_doc
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  # use parent_id to connect it with parent Nodejs package file
  def parse_project_doc(proj_doc, parent_id = nil)
    if proj_doc.nil? or proj_doc.has_key?(:jspm) == false
      log.error "JSPM project file has no `:jspm` subdocument: {proj_doc}"
      return nil
    end

    # JSPM is usually embedded into parent package.json file
    project = init_project(proj_doc, parent_id)
    jspm_doc = proj_doc[:jspm]

    parse_dependencies(
      project, jspm_doc[:dependencies], Dependency::A_SCOPE_COMPILE, proj_doc[:registry]
    )
    parse_dependencies(
      project, jspm_doc[:devDependencies], Dependency::A_SCOPE_DEVELOPMENT, proj_doc[:registry]
    )

    parse_dependencies(
      project, jspm_doc[:peerDependencies], Dependency::A_SCOPE_OPTIONAL, proj_doc[:registry]
    )

    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def parse_dependencies(project, deps, scope, default_registry = nil)
    deps.to_a.each do |pkg_id, dep_line|
      parse_dependency(project, pkg_id.to_s, dep_line, scope, default_registry)
    end

    project
  end


  def parse_dependency(project, pkg_id, dep_line, scope, default_registry)
    if dep_line[0..5] == 'github'
      #TODO if pkg is from GITHUB
      version_label = 'git'
      product = nil
    else
      version_label = dep_line.to_s.split('@').last
      product = Product::fetch_product(Product::A_LANGUAGE_NODEJS, pkg_id)
    end


    dep = init_dependency(product, pkg_id)
    dep[:scope] = scope
    parse_requested_version( version_label, dep, product )

    project.projectdependencies.push dep
    project.out_number     += 1 if ProjectdependencyService.outdated?( dep )
    project.unknown_number += 1 if product.nil?
    project
  end

  def init_project(proj_doc, parent_id = nil)
    project_name = if proj_doc.has_key?(:name)
                      proj_doc[:name]
                   elsif proj_doc[:jspm].has_key?(:name)
                      proj_doc[:jspm][:name]
                   else
                      "jspm_project" + Time.now.to_i
                   end

    Project.new(
      parent_id: parent_id,
      name: project_name,
      project_type: Project::A_TYPE_JSPM,
      language: Product::A_LANGUAGE_NODEJS,
      description: proj_doc[:description],
      version: proj_doc[:version]
    )
  end
end

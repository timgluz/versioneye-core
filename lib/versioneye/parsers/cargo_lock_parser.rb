require 'tomlrb'

class CargoLockParser < CommonParser
  attr_reader :dep_rule

  def initialize
    @dep_rule = Regexp.new(
      '(?<name>\w.+)\s+(?<version>\d.+)\s+\((?<source>\w+)\+(?<source_url>\w.+)\)'
    )

  end

  def parse(url)
    return nil if url.to_s.empty?

    content = self.fetch_response_body url
    parse_content content
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  # parses dependencies from parsed content
  #params:
  # content - string, downloaded content of Cargo.lock file
  # token   - not required param, here's just to match with CommonParser
  def parse_content(content, token = nil)
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    doc = Tomlrb.parse(content, symbolize_keys: true)
    if doc.nil?
      log.error "Failed to parse Cargo.toml content: #{content}"
      return nil
    end

    project = init_project doc
    parse_dependencies doc, project

    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def parse_dependencies(project_doc, project)
    if project_doc[:root].has_key?(:dependencies) == false
      log.error "parse_dependencies: Cargo lock file has no :dependencies field"
      return project
    end

    if project_doc[:package].nil?
      log.error "parse_dependencies: Cargo.lock file misses packages field"
      return
    end

    #build lookup table for packages
    packages_idx = build_package_index(project_doc[:package])

    #parse parent dependencies and follow their subdependencies
    project_doc[:root][:dependencies].to_a.each do |dep_line|
      parse_recursive_dependencies(project, packages_idx, dep_line)
    end

    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def build_package_index(packages)
    packages.to_a.reduce({}) do |idx, pkg_doc|
      idx.store [pkg_doc[:name], pkg_doc[:version]], pkg_doc
      idx
    end
  end

  def parse_recursive_dependencies(project, packages_idx, dep_line, parent_dep = nil,  depth = 0)
    if depth > 32
      log.error "parse_recursive_dependencies: too deep stack - cycled deps"
      return
    end

    pkg_id, version_label = parse_dependency_line dep_line
    if pkg_id.nil?
      log.error "Failed to parse dependency line: #{dep_line}"
      return
    end

    parent_doc = packages_idx.fetch([ pkg_id, version_label ])
    product = Product.where(
      language: Product::A_LANGUAGE_RUST,
      prod_key: pkg_id
    ).first

    parent_dep = init_dependency(product, pkg_id, version_label, parent_dep, depth)
    parse_requested_version(version_label, parent_dep, product)

    project.out_number += 1 if ProjectdependencyService.outdated?(parent_dep)
    project.unknown_number += 1 if product.nil?
    project.dependencies << parent_dep

    #parse subdependencies from doc[:package].parentdoc[:dependencies]
    parent_doc[:dependencies].to_a.each do |sub_dep_line|
      parse_recursive_dependencies(
        project, packages_idx, sub_dep_line, parent_dep, depth += 1
      )
    end

    parent_dep
  end

  def parse_requested_version(version, dependency, product)
    version = version.to_s.strip
    dependency[:version_label]      = version

    if version.empty? or ['*', 'X', 'x'].include?(version)
      log.error "#{product} version label is missing."
      update_requested_with_current(dependency, product)
      return dependency
    end

    if product.nil?
      log.error "dependency #{dependency} has no product or its unknown"
      dependency[:version_requested]  = version
      return dependency
    end

    version_db = product.versions.where(version: version).first
    if version_db.nil?
      log.error "#{product} has no match for #{version}"
      update_requested_with_current(dependency, product)
      return dependency
    end

    dependency[:version_requested]   = version
    dependency[:version_label]       = version
    dependency[:comperator]          = '='

    dependency
  end


  def parse_dependency_line(dep_text)
    m = @dep_rule.match dep_text.to_s.strip
    return if m.nil?

    [m[:name], m[:version]]
  end

  def init_project(project_doc)
    Project.new(
      project_type: Project::A_TYPE_CARGO,
      language: Product::A_LANGUAGE_RUST,
      name: project_doc[:root][:name],
      version: project_doc[:root][:version]
    )
  end

  def init_dependency(product, pkg_id, version_label, parent_dep = nil, depth = 0)
    parent_dep = {} if parent_dep.nil?

    dep = Projectdependency.where(
      name: pkg_id,
      language: Product::A_LANGUAGE_RUST,
      version_label: version_label,
      parent_prod_key: parent_dep[:prod_key],
      parent_version: parent_dep[:version_label]
    ).first_or_initialize

    if product
      dep[:language] = product[:language]
      dep[:prod_key] = product[:prod_key]
      dep[:version_current] = product[:version]
    end

    if parent_dep
      dep[:transitive] = (depth > 0) ? true : false
      dep[:parent_id] = parent_dep[:id]
      dep[:parent_prod_key] = parent_dep[:prod_key]
      dep[:parent_version] = parent_dep[:version_label]
      dep[:deepness] = depth.to_i
    end

    dep
  end

end

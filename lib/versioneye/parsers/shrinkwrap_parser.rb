class ShrinkwrapParser < PackageParser
  A_MAX_DEPTH = 32

  def parse_content(content, token = nil)
    content = content.to_s.strip
    return nil if content.empty?
    return nil if (content =~ /Not\s+found/i)

    proj_doc = from_json content
    return nil if proj_doc.nil?

    project = init_project({
      'name'        => proj_doc[:name],
      'version'     => proj_doc[:version],
      'description' => "npm-shrinkwrap.json"
    })

    parse_dependency_items proj_doc, project
    project
  end

  def parse_dependency_items(proj_doc, project)
    proj_doc[:dependencies].to_a.each do |dep_id, dep_doc|
      parse_dependency(dep_id, dep_doc, project)
    end

    project
  end

  def parse_dependency(dep_id, dep_doc, project, depth = 0, parent_id = nil)
    return nil if depth > A_MAX_DEPTH

    product = Product.where(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: dep_id
    ).first

    #process dependency data and update project details
    dep_db = init_dependency(product, dep_id, dep_doc, depth, parent_id)
    parse_requested_version dep_db[:version_requested], dep_db, product
    project.dep_number     += 1
    project.out_number     += 1 if ProjectdependencyService.outdated?( dep_db )
    project.unknown_number += 1 if product.nil?
    project.projectdependencies.push dep_db

    #process subdependencies
    dep_doc[:dependencies].to_a.each do |sub_dep_id, sub_dep_doc|
      parse_dependency(sub_dep_id, sub_dep_doc, project, depth + 1, dep_db.id)
    end

    project
  end

  def init_dependency(product, dep_id, dep_doc, depth = 0, parent_id = nil)
    version_label = dep_doc[:from].to_s.split('@').last
    dep = Projectdependency.new({
      parent_id: parent_id,
      language: Product::A_LANGUAGE_NODEJS,
      name: dep_id,
      prod_key: dep_id,
      comperator: '=',
      version_label: version_label,
      version_requested: dep_doc[:version],
      transitive: (depth > 0),
      deepness: depth,
      scope: Dependency::A_SCOPE_COMPILE
    })

    if product
      dep[:version_current] = product[:version]
    end

    dep
  end

end

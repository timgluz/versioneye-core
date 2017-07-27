require 'versioneye/parsers/common_parser'

# a parser for CPAN meta.yaml files
class MetaYamlParser < CpanParser

  def parse_content(meta_txt, token = nil)
    return if meta_txt.to_s.empty?

    meta_doc = from_yaml meta_txt
    if meta_doc.nil?
      logger.error "parse_content: unparseable meta.yml document"
      return
    end

    project = init_project 'meta.yml project'
    deps = parse_dependencies(meta_doc)
    save_project_dependencies(project, deps)

    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    logger.error "MetaYamlParser: error in parse_content"
    logger.error "\treason: #{e.message}"
    logger.error e.backtrace.join('\n')
    nil
  end

  # extracts dependency info from project file and initializes Dependency models
  def parse_dependencies(meta_doc)
    deps = []

    if meta_doc.nil? or meta_doc.empty?
      logger.error "parse_dependencies: no content"
      return deps
    end

    # required dependencies
    deps += init_dependencies(meta_doc['requires'], Dependency::A_SCOPE_RUNTIME)
    deps += init_dependencies(meta_doc['build_requires'], Dependency::A_SCOPE_BUILD)
    deps += init_dependencies(meta_doc['develop_requires'], Dependency::A_SCOPE_DEVELOPMENT)

    deps += init_dependencies(meta_doc['configure_requires'], Dependency::A_SCOPE_CONFIGURE)
    deps += init_dependencies(meta_doc['test_requires'], Dependency::A_SCOPE_TEST)

    # recommended dependencies
    deps += init_dependencies(meta_doc['recommends'], Dependency::A_SCOPE_RUNTIME)
    deps += init_dependencies(meta_doc['build_recommends'], Dependency::A_SCOPE_BUILD)
    deps += init_dependencies(meta_doc['develop_recommends'], Dependency::A_SCOPE_DEVELOPMENT)
    deps += init_dependencies(meta_doc['configure_recommends'], Dependency::A_SCOPE_CONFIGURE)
    deps += init_dependencies(meta_doc['test_recommends'], Dependency::A_SCOPE_TEST)

    # suggested dependencies
    deps += init_dependencies(meta_doc['suggests'], Dependency::A_SCOPE_RUNTIME)
    deps += init_dependencies(meta_doc['build_suggests'], Dependency::A_SCOPE_BUILD)
    deps += init_dependencies(meta_doc['develop_suggests'], Dependency::A_SCOPE_DEVELOPMENT)
    deps += init_dependencies(meta_doc['configure_suggests'], Dependency::A_SCOPE_CONFIGURE)
    deps += init_dependencies(meta_doc['test_suggests'], Dependency::A_SCOPE_TEST)


    deps
  end

  def init_dependencies(deps_doc, scope)
    deps_doc.to_a.reduce([]) do |acc, row|
      prod_key, version_label = row.to_a
      acc << init_dependency(prod_key, version_label, scope)
      acc
    end.to_a
  end

  def init_dependency(prod_key, version_label, scope)
    Projectdependency.new(
      language: Product::A_LANGUAGE_PERL,
      prod_key: prod_key,
      name: prod_key,
      version_label: version_label,
      scope: scope.to_s.downcase
    )
  end


end

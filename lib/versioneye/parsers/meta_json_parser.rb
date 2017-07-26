require 'versioneye/parsers/common_parser'

class MetaJsonParser < CpanParser

  def parse_content(meta_txt, token = nil)
    return if meta_txt.to_s.empty?

    meta_doc = from_json meta_txt
    if meta_doc.nil?
      logger.error "parse_content: empty meta.json document"
      return
    end

    project = init_project 'meta.json project'
    deps = parse_dependencies(meta_doc[:prereqs])
    save_project_dependencies(project, deps)

    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "MetaJsonParser: error in parse_content. #{e.message} \n #{meta_doc}"
    log.error e.backtrace.join('\n')
    nil
  end

  # takes map of CPAN required packages and turns into list of Dependency
  def parse_dependencies(reqs_doc)
    deps = []

    if reqs_doc.nil? or reqs_doc.empty?
      logger.error "parse_dependencies: meta_doc has no data in :prereqs field"
      return deps
    end

    if reqs_doc.is_a?(Hash) == false
      logger.error "parse_dependencies: the doc of requirements is not Hashmap"
      return deps
    end

    reqs_doc.each_pair do |scope, req_group|
      # merge requires, recommends, suggests and etc groups into one
      prods = req_group.values.to_a.reduce({}) {|acc, x| acc.merge!(x); acc}

      # initialize a Projectdependency models for each product
      prods.to_a.each do |prod_key, version_label|
        deps << init_dependency(prod_key.to_s, version_label.to_s, scope.to_s)
      end
    end

    deps
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

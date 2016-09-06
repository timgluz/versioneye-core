require 'gemnasium/parser'

#require 'versioneye/parsers/gemfile_parser'

class GemspecParser < GemfileParser

  def parse(url)
    if url.to_s.empty?
      log.error "parse: the url cant be empty"
      return
    end

    content = fetch_response_body(url)
    parse_content(content, url)
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
  end

  def parse_content(the_content, url = nil)
    the_content = the_content.to_s.strip
    return nil if the_content.empty?
    res = Gemnasium::Parser.gemspec(the_content)
    
    project = init_project(url)
    deps = init_dependencies(res.dependencies)
    check_dependencies!(project, deps)
    
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "parse_content: failed to parse `#{the_content}` -> #{e.message}"
    log.error e.backtrace.join('\n')
  end

  def init_project(url)
    project = Project.new({
      project_type: Project::A_TYPE_RUBYGEMS,
      language: Product::A_LANGUAGE_RUBY,
      url: url
    })

    project
  end

  #parses version label and check is dependencies outdated or not
  def check_dependencies!(project, deps)
  
    deps.to_a.each do |dep|
      product = Product.find_by(language: Product::A_LANGUAGE_RUBY, prod_key: dep[:prod_key])
      if product.nil?
        log.warn "check_dependencies: found no #{Product::A_LANGUAGE_RUBY} by prod_key #{dep[:prod_key]}"
        project.unknown_number += 1
        next
      end

      dep[:version_current] = product[:version]
      parse_requested_version(dep[:version_label], dep, product)
      project.out_number += 1 if ProjectdependencyService.outdated?(dep)
      project.projectdependencies << dep
      project
    end
  end

  def init_dependencies(gemspec_deps)
    gemspec_deps.to_a.reduce([]) {|acc, dep| acc << init_dependency(dep); acc}
  end

  def init_dependency(gemspec_dep)
    prod_name = gemspec_dep.name.to_s.strip
    version_label = gemspec_dep.requirement.to_s.strip
    scope = to_scope_constant(gemspec_dep.type)

    Projectdependency.new({
      name: prod_name,
      prod_key: prod_name,
      language: Product::A_LANGUAGE_RUBY,
      version_label: version_label,
      scope: scope
    })
  end

  def to_scope_constant(scope_key)
    case scope_key
    when :runtime     then Dependency::A_SCOPE_RUNTIME
    when :test        then Dependency::A_SCOPE_TEST
    when :development then Dependency::A_SCOPE_DEVELOPMENT
    else
      scope_key.to_s
    end
  end
end

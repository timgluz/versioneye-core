require 'semverly'
require 'versioneye/parsers/common_parser'
require 'yaml'

# parser for Golang Glide.yaml files
#
# DOCS:
# https://github.com/Masterminds/glide
# https://glide.readthedocs.io/en/latest/glide.yaml/

class GlideParser < GodepParser
  def parse(url)
    if url.to_s.empty?
      log.error "GlideParser cant handle empty urls"
      return
    end

    body = self.fetch_response_body url
    parse_content body
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    return nil
  end

  def parse_content(content, token = nil)
    if content.to_s.empty?
      log.error "parse_content:  got empty document, cancelling parsing"
      return
    end

    glide_doc = from_yaml content
    if glide_doc.nil?
      log.error "parse-content: failed to parse YAML document: `#{content}`"
      return
    end

    project = init_project glide_doc
    parse_dependencies(project, glide_doc['import'], Dependency::A_SCOPE_COMPILE)
    parse_dependencies(project, glide_doc['testImport'], Dependency::A_SCOPE_TEST)

    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def parse_dependencies(project, deps, scope)
    if deps.nil? or deps.empty?
      log.error "parse_dependencies: got no dependencies for #{project}"
      return
    end

    deps.to_a.each {|dep| parse_dependency(project, dep, scope) }
    project
  end

  def parse_dependency(project, dep_doc, scope)
    dep_id = dep_doc['package'].to_s.strip
    prod_db = Product.fetch_product(Product::A_LANGUAGE_GO, dep_id)

    dep_db = init_dependency( prod_db, dep_id, scope)
    dep_db = parse_requested_version(dep_doc['version'], dep_db, prod_db)
    add_dependency_to_project(project, dep_db, prod_db)

    project
  end

  def init_project(glide_doc)
    Project.new(
      project_type: Project::A_TYPE_GLIDE,
      language: Product::A_LANGUAGE_GO,
      name: glide_doc[:package].to_s
    )
  end

  def init_dependency(prod_db, dep_id, scope = Dependency::A_SCOPE_COMPILE)
    dep_db = Projectdependency.new(
      language: Product::A_LANGUAGE_GO,
      prod_key: dep_id,
      name: dep_id
    )

    dep_db[:scope] = scope

    if prod_db
      dep_db[:version_current] = prod_db[:version]
    end

    dep_db
  end
end

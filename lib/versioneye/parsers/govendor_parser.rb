require 'versioneye/parsers/common_parser'
require 'versioneye/parsers/godep_parser'

# parser for Govendor package manage
# it supports vendor/vendor.json files
# docs:
# https://github.com/kardianos/govendor
#

class GovendorParser < GodepParser
  def parse(url)
    if url.to_s.empty?
      log.error "#{self.class.name} cant handle empty urls"
      return
    end

    body = fetch_response_body url
    parse_content body
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    return nil
  end

  def parse_content(content, token = nil)
    if content.to_s.empty?
      log.error "parse_content: got empty document, stopping parser"
      return
    end

    pkg_doc = from_json content
    if pkg_doc.nil?
      log.error "parse_content: failed to parse Vendor.json: `#{content}`"
      return
    end

    project = init_project pkg_doc
    parse_dependencies( project, pkg_doc[:package] )
  end

  def parse_dependencies(project, deps)
    if deps.nil? or deps.empty?
      log.error "parse_dependencies: got no dependencies for #{project}"
      return
    end

    deps.to_a.each {|dep| parse_dependency(project, dep) }

    project
  end

  def parse_dependency(project, dep_doc)
    dep_id = dep_doc[:path].to_s.strip
    prod_db = Product.fetch_product(Product::A_LANGUAGE_GO, dep_id)

    dep_db = init_dependency(prod_db, dep_id)
    dep_db[:commit_sha] = dep_doc[:revision]
    dep_db[:version_label] = dep_doc[:revision]

    dep_db = parse_requested_version(dep_db[:version_label], dep_db, prod_db)
    add_dependency_to_project(project, dep_db, prod_db)

    project
  end

  def init_project(pkg_doc)
    Project.new(
      project_type: Project::A_TYPE_GOPKG,
      language: Product::A_LANGUAGE_GO,
      name: pkg_doc[:rootPath].to_s,
      description: 'GovendorParser'
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

require 'versioneye/parsers/common_parser'
require 'versioneye/parsers/godep_parser'

# parser for Gokpg file used by Golang Dep pkg-manager
# it will be official package manager
#
# Docs:
# https://github.com/golang/dep

class GopkgParser < GodepParser
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

    gopkg_doc = from_toml content
    if gopkg_doc.nil?
      log.error "parse_content: failed to parse TOML document: `#{content}`"
      return
    end

    project = init_project gopkg_doc
    parse_dependencies(project, gopkg_doc[:constraint])

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
    dep_id = dep_doc[:name].to_s.strip
    prod_db = Product.fetch_product(Product::A_LANGUAGE_GO, dep_id)

    dep_db = init_dependency( prod_db, dep_id)
    dep_db[:version_label] = dep_doc[:version]
    dep_db[:commit_sha] = dep_doc[:rev]
    dep_db[:branch] = dep_doc[:branch]
    dep_db[:commit_tag] = dep_doc[:tag]


    version_label = (dep_db[:version_label] || dep_db[:commit_sha])
    version_label ||= dep_db[:tag]
    version_label ||= dep_db[:branch]

    dep_db = parse_requested_version(version_label, dep_db, prod_db)
    add_dependency_to_project(project, dep_db, prod_db)

    project
  end

  def init_project(gopkg_doc)
    Project.new(
      project_type: Project::A_TYPE_GOPKG,
      language: Product::A_LANGUAGE_GO,
      name: 'gopkg project',
      description: 'GopkgParser'
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

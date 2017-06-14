require 'versioneye/parsers/common_parser'
require 'semverly'


# parser for Godeps/Godeps.json
# https://github.com/tools/godep
class GodepParser < CommonParser

  def parse(url)
    if url.to_s.empty?
      log.error "#{self.class.name} cant handle empty urls"
      return
    end

    body = self.fetch_response_body url
    parse_content body
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    return nil
  end

  # params:
  #   content - string, Godep project file
  #   token - empty param, to match CommonParser.parse_content
  def parse_content(content, token = nil)
    if content.to_s.empty?
      log.error "GodepParser.parse_content: empty document"
      return
    end

    godeps_doc = from_json content #replaces unicode spaces and returns symbolized doc
    if godeps_doc.nil?
      log.error "GodepParser.parse_content: failed to parse #{content}"
      return
    end

    project = init_project godeps_doc
    parse_dependencies(project, godeps_doc[:Deps])

    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  #extracts project ids for crawler
  def extract_product_ids(content)
    raise "GodepParser.parse_content: empty document" if content.to_s.empty?

    godeps_doc = from_json content #replaces unicode spaces and returns symbolized doc
    raise "GodepParser.parse_content: failed to parse #{content}" if godeps_doc.nil?

    godeps_doc[:Deps].to_a.reduce([]) do |acc, dep|
      acc << dep[:ImportPath]
      acc
    end
  end

  def parse_dependencies(project, deps)
    return project if deps.to_a.empty?

    deps.each {|dep_doc| parse_dependency(project, dep_doc)}
    project
  end

  #parses version info of the item of godeps[:Deps] list
  def parse_dependency(project, dep_doc)
    dep_prod_key = dep_doc[:ImportPath].to_s.strip
    the_prod = Product.fetch_product( Product::A_LANGUAGE_GO, dep_prod_key)

    version_label = (dep_doc[:Rev] || dep_doc[:Comment])
    the_dep  = init_dependency( the_prod, dep_prod_key )
    the_dep[:commit_sha] = dep_doc[:Rev]
    the_dep[:tag] = dep_doc[:comment]

    common_branches = Set.new ['master', 'default', 'dev', 'test', 'release']
    if common_branches.include?(dep_doc[:branch])
      the_dep[:branch] = dep_doc[:branch]
    end

    the_dep  = parse_requested_version(version_label, the_dep, the_prod, dep_doc[:Comment])
    add_dependency_to_project(project, the_dep, the_prod)
    project
  end

  #TODO: add support for SEMVER selectors
  #TODO: add comperator for SHA, BRANCH, TAGS
  def parse_requested_version(version_label, dependency, product, dep_comment = nil)
    version_label = version_label.to_s.strip

    if version_label.to_s.strip.empty?
      update_requested_with_current(dependency, product)
      return dependency
    end

    if product.nil?
      dependency[:version_requested] = version_label
      dependency[:version_label]     = (dep_comment || version_label )
      return dependency
    end

    version_db = product.versions.find_by(tag: dep_comment) unless dep_comment.nil? #search by version tag
    version_db ||= product.versions.find_by(commit_sha: version_label)

    if version_db.nil?
      log.warn "GodepParser.parse_requested_version: failed to find version #{version_label} for #{product[:prod_key]}"
      dependency[:version_requested] = '0.0.0+NA'
      dependency[:version_label]     = version_label
      return dependency
    end

    # use version semver+sha<> if possible other wise just use SHA
    dependency[:version_requested] = (version_db[:version] ||  version_label ) #SEMVER_FROM_DB or SHA
    dependency[:version_label] = ( dep_comment || version_label ) #TAG or SHA

    dependency
  end

  def init_project(godep_doc)
    Project.new({
      project_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      name: godep_doc[:ImportPath],
      version: godep_doc[:GodepVersion]
    })
  end

  def init_dependency(product, dep_prod_key)
    cur_version =  ( product.nil? ? '0.0.0+NA' : product[:version] )

    Projectdependency.new({
      language: Product::A_LANGUAGE_GO,
      prod_key: dep_prod_key,
      name: dep_prod_key,
      version_current: cur_version,
      scope: Dependency::A_SCOPE_COMPILE
    })
  end
end


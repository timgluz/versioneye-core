require 'versioneye/parsers/common_parser'

class NugetParser < CommonParser

  attr_reader :rules

  def initialize
    # ATOMIC RULES
    numeric         = '\\d+'
    ident           = "[\\w-]" # identificator aka textual value
    prerelease_info = "\\-(?<prerelease>#{ident}[\\.#{ident}]*)" # matches release info: -alpha.1
    build_info      = "\\+(?<build>#{ident}[\\.#{ident}]*)"      # matches build info
    version         = "(?<version>(#{numeric})(\\.(#{numeric})(\\.(#{numeric}))?)?)"
    semver          = "#{version}(#{prerelease_info})?(#{build_info})?"

    #version range doc: https://docs.nuget.org/create/versioning#Specifying-Version-Ranges-in-.nuspec-Files
    empty_string    = "^\\s*$"                    # ""        | current
    less_equal      = "^\\(,#{semver}\\]$"        # (,1.0]    | x <= 1.0
    less_than       = "^\\(,#{semver}\\)$"        # (,1.0)    | x < 1.0
    exact_match     = "^\\[#{semver},{0,1}\\]$"   # [1.0]     | x == 1.0
    greater_than    = "^\\(#{semver},\\)$"        # (1.0,)    | 1.0 < x
    greater_eq_than = "^#{semver}$"               # 1.0       | 1.0 <= x, quite weird
    greater_eq_than2 = "^\\[#{semver},\\)$"       # [1.0,)    | 1.0 <= x, unofficial

    gt_range_lt   = "^\\((?<start>#{semver}),(?<end>#{semver})\\)$" # (1.0,2.0) | 1.0 < x < 2.0
    gte_range_lt  = "^\\[(?<start>#{semver}),(?<end>#{semver})\\)$" # [1.0,2.0) | 1.0 <= x < 2.0
    gt_range_lte  = "^\\((?<start>#{semver}),(?<end>#{semver})\\]$" # (1.0,2.0] | 1.0 < x <= 2.0
    gte_range_lte = "^\\[(?<start>#{semver}),(?<end>#{semver})\\]$" # [1.0,2.0] | 1.0 <= x <= 2.0

    # NB! before trying to match rules, be sure that string has no spaces/tabs
    @rules = {
      version:         Regexp.new(version,         Regexp::EXTENDED),
      semver:          Regexp.new(semver,          Regexp::EXTENDED),
      empty:           Regexp.new(empty_string,    Regexp::EXTENDED),
      less_than:       Regexp.new(less_than,       Regexp::EXTENDED),
      less_equal:      Regexp.new(less_equal,      Regexp::EXTENDED),
      exact:           Regexp.new(exact_match,     Regexp::EXTENDED),
      greater_than:    Regexp.new(greater_than,    Regexp::EXTENDED),
      greater_eq_than: Regexp.new(greater_eq_than, Regexp::EXTENDED),
      greater_eq_than2: Regexp.new(greater_eq_than2, Regexp::EXTENDED),
      gt_range_lt:     Regexp.new(gt_range_lt,     Regexp::EXTENDED),
      gte_range_lt:    Regexp.new(gte_range_lt,    Regexp::EXTENDED),
      gt_range_lte:    Regexp.new(gt_range_lte,    Regexp::EXTENDED),
      gte_range_lte:   Regexp.new(gte_range_lte,   Regexp::EXTENDED)
    }
  end

  def parse( url )
    response_body = fetch_response_body(url)
    if response_body.nil?
      log.error "Failed to fetch Nuget file from #{url}"
      return nil
    end

    parse_content( response_body, url )
  end

  def parse_content( response_body, url )
    deps = []

    doc     = fetch_xml( response_body )
    project = init_project( url, doc )
    deps    = parse_dependencies( doc )

    parse_dependency_versions(project, deps) # attaches parsed dependencies to project
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "ERROR in parse_content(#{response_body}) -> #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end

  # parses raw version label and updates dependency.version_requested with latest matching version
  def parse_requested_version(version_label, dependency, product)
    return dependency if product.nil?

    latest_version = parse_version_data(version_label, product)
    return dependency if latest_version.nil?

    dependency[:version_label] = latest_version[:label]
    dependency[:version_requested] = latest_version[:version]
    dependency[:comperator] = latest_version[:comperator]

    dependency
  end

  def cleanup_version(version_label)
    version_label.to_s.gsub(/\s*/, "").strip
  end

  # parses raw version label and matches its comperator range with Product versions
  def parse_version_data(version_label, product)
    version = cleanup_version(version_label)

    version_data = {
      version: version,
      label: version,
      comperator: '='
    }

    if product.nil?
      log.warn "parse_version_data | product is nil"
      return version_data
    end

    if version.empty?
      newest = VersionService.newest_version(product.versions)
      version_data[:version] = newest.version if newest
      version_data[:label] = '*'
    elsif ( m = rules[:exact].match(version) )
      res = VersionService.from_ranges(product.versions, m[:version])
      version_data[:version] = res.last.version unless res.to_a.empty?
      version_data[:comperator] = '='

    elsif ( m = rules[:less_than].match(version) )
      res = VersionService.smaller_than(product.versions, m[:version], true)
      version_data[:version]    = res.last.version unless res.to_a.empty?
      version_data[:comperator] = '<'

    elsif ( m = rules[:less_equal].match(version) )
      res = VersionService.smaller_than_or_equal(product.versions, m[:version], true)
      version_data[:version]    =  res.last.version unless res.to_a.empty?
      version_data[:comperator] = '<='

    elsif ( m = rules[:greater_than].match(version) )
      res = VersionService.greater_than(product.versions, m[:version], true)
      version_data[:version]    = res.last.version unless res.to_a.empty?
      version_data[:comperator] = '>'

    elsif ( m = rules[:greater_eq_than].match(version) or m = rules[:greater_eq_than2].match(version))
      res = VersionService.greater_than_or_equal(product.versions, m[:version], true)
      version_data[:version]    = res.last.version unless res.to_a.empty?
      version_data[:comperator] = '>='

    elsif ( m = rules[:gt_range_lt].match(version) )
      start_version = m[:start]
      end_version = m[:end]

      #1st find all the greatest versions, then smallest; then find biggest of intersection
      gt_versions = VersionService.greater_than(product.versions, start_version, true)
      lt_versions = VersionService.smaller_than(product.versions, end_version, true)
      latest = VersionService.intersect_versions(gt_versions, lt_versions, false)
      version_data[:version]    = latest.version if latest
      version_data[:comperator] = '>x<'

    elsif ( m = rules[:gte_range_lt].match(version) )
      start_version = m[:start]
      end_version = m[:end]
      gt_versions = VersionService.greater_than_or_equal(product.versions, start_version, true)
      lt_versions = VersionService.smaller_than(product.versions, end_version, true)
      latest = VersionService.intersect_versions(gt_versions, lt_versions, false)
      version_data[:version]    = latest.version if latest
      version_data[:comperator] = '>=x<'

    elsif ( m = rules[:gt_range_lte].match(version) )
      start_version = m[:start]
      end_version = m[:end]
      gt_versions = VersionService.greater_than(product.versions, start_version, true)
      lt_versions = VersionService.smaller_than_or_equal(product.versions, end_version, true)
      latest = VersionService.intersect_versions(gt_versions, lt_versions, false)
      version_data[:version]    = latest.version if latest
      version_data[:comperator] = '>x<='

    elsif ( m = rules[:gte_range_lte].match(version) )
      start_version = m[:start]
      end_version = m[:end]
      gt_versions = VersionService.greater_than_or_equal(product.versions, start_version, true)
      lt_versions = VersionService.smaller_than_or_equal(product.versions, end_version, true)
      latest = VersionService.intersect_versions(gt_versions, lt_versions, false)
      version_data[:version]    = latest.version if latest
      version_data[:comperator] = '>=x<='
    else
      log.error "NugetParser.parse_version_data | version `#{version}` has wrong format"
      version_data[:version] = "0.0.0-NA"
      version_data[:comperator] = '!='
    end

    version_data
  end

  def parse_dependencies(doc)
    deps = []
    deps_node = doc.xpath('//package/metadata/dependencies')
    # Nuget 2.0
    deps_node.xpath('group').each do |group|
      deps.concat parse_group_dependencies(group, group.attr('targetFramework'))
    end
    # Nuget 1.0
    deps_node.xpath('dependency').each {|node| deps << parse_dependency(node)}

    deps
  end


  def parse_group_dependencies(group, target)
    deps = []
    group.xpath('dependency').each do |node|
      deps << parse_dependency(node, target)
    end

    deps
  end


  def parse_dependency(node, target = nil, scope = nil)
    prod_name = node.attr("id").to_s.strip
    version_label = node.attr("version").to_s.strip

    Projectdependency.new({
      language: Product::A_LANGUAGE_CSHARP,
      name: prod_name,
      prod_key: prod_name,
      version_label: version_label,
      version_requested: version_label,
      target: target,
      scope: scope
    })
  end


  def parse_dependency_versions(project, deps)
    return if deps.nil?

    deps.each {|dep| parse_dependency_version( project, dep )}
  end

  #parses raw version string of project dependencies and updates project details
  def parse_dependency_version( project, dependency )
    product = Product.fetch_product(dependency[:language], dependency[:prod_key])
    version_label = dependency[:version_label]

    if version_label.nil? || version_label.empty?
      update_requested_with_current( dependency, product )
      return project
    end

    if product
      parse_requested_version(version_label, dependency, product)
      dependency[:version_current] = product.version
    else
      dependency.comperator = "="
      project.unknown_number += 1
    end

    project.projectdependencies.push(dependency)
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 if product.nil?
    project
  end

  def init_project(url, doc)
    project = Project.new({
      project_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      url: url,
      name: doc.xpath('//package/metadata/id').text,
      description: doc.xpath('//package/metadata/description').text,
      license: doc.xpath('//package/metadata/licenseUrl').text
    })

    project
  end
end

require 'versioneye/parsers/common_parser'

class NugetParser < CommonParser

  attr_reader :rules

  def initialize
    # ATOMIC RULES
    numeric         = '\\d+'
    ident           = "[\\w-]" # identificator aka textual value
    prerelease_info = "\\-(?<prerelease>#{ident}[\\.#{ident}]*)" # matches release info: -alpha.1
    build_info      = "\\+(?<build>#{ident}[\\.#{ident}]*)"      # matches build info
    version         = "(?<version>(#{numeric})(\\.(#{numeric})(\\.(#{numeric}))*)?)" #matches more than m.m.p

    semver          = "(?<semver>#{version}(#{prerelease_info})?(#{build_info})?)"

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

  # removes leading zeros and excess 0 after patch part
  #breaking changes from 3.4 
  #details: https://docs.microsoft.com/en-us/nuget/create-packages/dependency-versions
  def normalize_version(version_label)
    version, metadata, separator = split_version( version_label )

    # remove spaces in the label
    version = version.gsub(/\s/, '')
    #replace leading zeros in version number
    version = version.gsub(/\b0+(\d+)\b/, '\1')
    # remove leading 0 if version has 4part: 1.1.1.0 -> 1.1.1
    if version.match /^\d+(\.\d+){2,2}\.0+/
      rpos = version.rindex('.') - 1
      version = version[0..rpos]
    end

    lbl = version.to_s.strip
    lbl += (separator.to_s + metadata) unless metadata.to_s.empty?

    lbl
  end

  # adds missing minor, patch part as 0
  def pad_zeros(version_label)
    version, metadata, separator = split_version( version_label )

    padded_version = case (version + ' ') #hack to make negation to work
                     when /^\d+(?!\.)/ then version + '.0.0'
                     when /^\d+\.\d+(?!\.)/ then version + '.0'
                     else version
                     end

    padded_version += (separator.to_s + metadata) unless metadata.to_s.empty?
    padded_version
  end

  # separates version from metadata, so we could manipulate version without changing metadata
  # returns:
  #   [version, metadata, separator] - separator is earliest build (+) or prerelease (-) separator
  def split_version(version_label)
    version_label = version_label.to_s.strip

    build_start = version_label.index('+').to_i
    prerelease_start = version_label.index('-').to_i

    #-- split version so metadata would stay untouched
    separator = if build_start == 0 and prerelease_start == 0
                  '--' #shouldnt exist, so it doesnt split string
                elsif prerelease_start == 0 or (build_start != 0 and build_start < prerelease_start )
                  '+'
                elsif build_start == 0 or (prerelease_start != 0 and prerelease_start < build_start)
                  '-'
                end
    version, _, metadata = version_label.partition separator
    [version, metadata, separator]
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

    version_label = cleanup_version version_label

    # Ignore cases like => "dev-master | ^1.0"
    if version_label.match(/.+\|.+/).nil?
      dependency[:stability] = VersionTagRecognizer.stability_tag_for version_label
      VersionTagRecognizer.remove_minimum_stability version_label
    else
      dependency[:stability] = VersionTagRecognizer::A_STABILITY_STABLE
    end

    latest_version = parse_version_data(version_label, product)
    return dependency if latest_version.nil?

    dependency[:version_label] = latest_version[:label]
    dependency[:version_requested] = latest_version[:version]
    dependency[:comperator] = latest_version[:comperator]

    dependency
  end

  def cleanup_version(version_label)
    version_label.to_s.gsub(/\s+/, "").strip
  end

  # parses raw version label and matches its comperator range with Product versions
  def parse_version_data(version_label, product)
    version = cleanup_version(version_label)

    version_data = {
      version: version, #it uses unparsed version label only if version filtering failed
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
      lbl = m[:semver].to_s.strip
      possible_formats = [lbl, normalize_version(lbl), pad_zeros(lbl), (lbl + '.0')] 
      res = VersionService.versions_by_whitelist(product.versions, possible_formats)
      latest_version = VersionService.newest_version res

      version_data[:version] = latest_version[:version] if latest_version
      version_data[:comperator] = '='

    elsif ( m = rules[:less_than].match(version) )
      latest_version = VersionService.smaller_than(product.versions, m[:semver])
      version_data[:version]    = latest_version[:version] if latest_version
      version_data[:comperator] = '<'

    elsif ( m = rules[:less_equal].match(version) )
      latest_version = VersionService.smaller_than_or_equal(product.versions, m[:semver])
      version_data[:version]    =  latest_version[:version] if latest_version
      version_data[:comperator] = '<='

    elsif ( m = rules[:greater_than].match(version) )
      latest_version = VersionService.greater_than(product.versions, m[:semver])
      version_data[:version]    = latest_version[:version] if latest_version
      version_data[:comperator] = '>'

    elsif ( m = rules[:greater_eq_than].match(version) or m = rules[:greater_eq_than2].match(version))
      latest_version = VersionService.greater_than_or_equal(product.versions, m[:semver])
      version_data[:version] = latest_version[:version] if latest_version
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
      log.error "NugetParser.parse_version_data | version `#{version}` doesnt match with any parser rules"
      version_data[:version] = "0.0.0-NA"
      version_data[:comperator] = '!='
    end

    version_data
  rescue Exception => e
    log.error "NugetParser.parse_version_data: Failed to find match for version label #{version} for #{product.prod_id}"
    log.error e.backtrace.inspect
    return nil
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

    dep = Projectdependency.new({
      language: Product::A_LANGUAGE_CSHARP,
      name: prod_name,
      prod_key: prod_name,
      version_label: version_label,
      version_requested: version_label,
      target: target,
      scope: scope
    })

    dep
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

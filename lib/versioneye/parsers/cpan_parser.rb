require 'versioneye/parsers/common_parser'
require 'semverly'

class CpanParser < CommonParser
  attr_reader :rules, :comperators

  def initialize
    #MATCHER RULES
    empty_string_rule   = "\\s*$"
    version_rule        = "(?<version>v?\\d([\\.|\\-|\\+]\\w+)*)"
    comperator_rule     = "(?<comperator>[<|>|=|!]=?)"
    version_range_rule  = "(?<range>#{comperator_rule}?\\s*#{version_rule})"
    one_or_many_ranges  = "(?<ranges>#{version_range_rule}(\\s*,\\s*#{version_range_rule})*)"
    package_key_rule    = "(?<package>[\\w|\\:|\\-|\\_]+)"
    dependency_rule     = "(?<dep>#{package_key_rule}\\s*,\\s*#{one_or_many_ranges};)"
    require_keywords    = "\\A(requires|recommends|suggests)"
    plain_dependency    = "#{require_keywords}\\s+#{package_key_rule}\\s*;"
    scope_keywords      = "configure|build|test|develop|runtime"
    block_start_rule    = "\\Aon\\s+(?<scope>#{scope_keywords})\\s*=>\\s*sub\\s*{"
    block_end_rule      = "\\A\\}\\;"
    @comperators        = Set.new(['<', '<=', '>', '>=', '==', '!='])
    @rules = {
      empty:      Regexp.new(empty_string_rule, Regexp::EXTENDED ),
      version:    Regexp.new( version_rule , Regexp::EXTENDED | Regexp::IGNORECASE ),
      comperator: Regexp.new( comperator_rule, Regexp::EXTENDED ),
      range:      Regexp.new( version_range_rule, Regexp::EXTENDED ),
      ranges:     Regexp.new( one_or_many_ranges, Regexp::EXTENDED ),
      package:    Regexp.new( package_key_rule, Regexp::EXTENDED ),
      dependency: Regexp.new( dependency_rule, Regexp::EXTENDED ),
      plain_dependency: Regexp.new( plain_dependency, Regexp::EXTENDED ), #when only package name;
      requires:   Regexp.new( require_keywords, Regexp::EXTENDED ),
      block_start: Regexp.new( block_start_rule, Regexp::EXTENDED | Regexp::IGNORECASE ),
      block_end:  Regexp.new( block_end_rule, Regexp::EXTENDED | Regexp::IGNORECASE )
    }
  end

  def parse(url)
    if url.to_s.empty?
      log.error "CpanParser: url was empty"
      return nil
    end

    body = self.fetch_response_body(url)
    if body.to_s.empty?
      log.error "CpanParser: got empty document from the #{url}"
      return nil
    end

    parse_content(body, url)
  end
  
  def parse_content(cpan_doc, url = "")
    return nil if cpan_doc.empty?

    project = init_project(url)
    deps = parse_dependencies(cpan_doc)
    save_project_dependencies(project, deps)
    
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "CpanParser: error in parse_content. #{e.message} \n #{cpan_doc}"
    log.error e.backtrace.join('\n')
    nil
  end

  #analysises raw version-label and finds latest matching version
  def parse_requested_version(version_label, dep, product)
    version_label = version_label.to_s.strip

    if product.nil?
      dep[:version_requested] = version_label
      dep[:version_label] = version_label
      dep[:comperator] = '?'
      return dep
    end

    #handle empty version or null version
    if version_label.empty? or version_label == '0'
      dep[:version_label] = '>= 0'
      dep[:comperator]    = '>='
      return update_requested_with_current(dep, product)
    end

    #split it by commas and get latest version for each range
    ranges = version_label.split(/\,/)
    intersection = []
    comperators = []
    ranges.to_a.each do |range|
      comperator, latest_versions = match_version_range(range, product)
      if comperator and latest_versions
        comperators << comperator
        if intersection.empty?
          intersection = latest_versions
        else
          intersection = VersionService.intersect_versions(intersection, latest_versions)
        end
      end
    end

    if intersection.empty?
      log.error "CpanParser.parse_requested_version: Failed to parse the range `#{version_label}`"
      return update_requested_with_current(dep, product)
    else
      latest_version = VersionService.newest_version(intersection)

      dep[:comperator] = comperators.join(',')
      dep[:version_requested] = latest_version.to_s
    end


    dep
  end


  def match_version_range(version_label, product)
    m = @rules[:range].match(version_label)
    comperator = m[:comperator].to_s.strip
    version    = m[:version].to_s.strip

    if comperator.empty? and version
      latest_versions = VersionService.greater_than_or_equal(product.versions, version, true)
      ['>=', latest_versions]

    elsif comperator == '==' and version
      matching_versions = product.versions.to_a.keep_if {|v| v[:version] == version}
      [comperator, matching_versions]

    elsif comperator == '<' and version
      latest_versions = VersionService.smaller_than(product.versions, version, true)
      [comperator, latest_versions]

    elsif comperator == '<=' and version
      latest_versions = VersionService.smaller_than_or_equal(product.versions, version, true)
      [comperator, latest_versions]

    elsif comperator == '>' and version
      latest_versions = VersionService.greater_than(product.versions, version, true)
      [comperator, latest_versions]

    elsif comperator == '>=' and version
      latest_versions = VersionService.greater_than_or_equal(product.versions, version, true)
      [comperator, latest_versions]

    elsif comperator == '!=' and version
      latest_versions = VersionService.newest_but_not(product.versions, version, true)
      [comperator, latest_versions]

    else
      log.warn "parse_requested_version: failed to match version_label `#{version_label}`"
      [nil, nil]
    end
  end

  #parses dependency labels and checks outdated dependencies
  def save_project_dependencies(project, deps)
    deps.to_a.each {|dep| save_project_dependency(project, dep)}
    project
  end

  def save_project_dependency(project, dep)
    product = Product.find_by(language: Product::A_LANGUAGE_PERL, prod_key: dep[:prod_key])
    if product
      dep[:version_current] = product.version
    end

    if dep[:version].to_s.empty? and product
      dep[:version] = product.version
    end

    parse_requested_version(dep[:version_label], dep, product)
    project.out_number += 1 if ProjectdependencyService.outdated?(dep)
    project.unknown_number += 1 if product.nil?
    project.projectdependencies << dep

    project
  end

  #process raw text file and extracts dependency info line by line
  def parse_dependencies(cpan_doc)
    lines = cpan_doc.split(/\n+/)
    deps = []
    current_scope = 'runtime'
    lines.each do |line|
      new_scope, parsed_dep = parse_line(current_scope, line)
      current_scope = new_scope if current_scope != new_scope

      deps << parsed_dep if parsed_dep
    end

    deps
  end

  #parses runtime scope or dependency details from the line;
  def parse_line(current_scope, line)
    line = line.to_s.strip.gsub(/\'|\"/, '')
    if line.empty?
      return [current_scope, nil]
    end

    if ( m = @rules[:block_start].match(line) )
      [m[1].to_s.strip, nil]
    elsif (m = @rules[:block_end].match(line) )
      ['runtime', nil]

    elsif ( m = @rules[:requires].match(line) )
      dep = extract_dependency( current_scope, line )
      [current_scope, dep]
    else
      [current_scope, nil]
    end
  end

  #extract dependency details from requirement line
  def extract_dependency(current_scope, line)
    if ( m = @rules[:dependency].match(line) )
      init_dependency(m[:package], m[:ranges], current_scope)
    
    elsif ( m = @rules[:plain_dependency].match(line) )
      init_dependency(m[:package], nil, current_scope)
    else
      log.error "CpanParser.parse_line: failed to parse dependency data from the line `#{line}`"
      return nil
    end
  end

  def init_project(url)
    Project.new({
      project_type: Project::A_TYPE_CPAN,
      language: Product::A_LANGUAGE_PERL,
      name: 'CPAN project',
      url: url
    })
  end

  def init_dependency(prod_key, version_label, scope)
    Projectdependency.new({
      language: Product::A_LANGUAGE_PERL,
      name: prod_key,
      prod_key: prod_key,
      scope: scope,
      version_label: version_label
    })
  end
end

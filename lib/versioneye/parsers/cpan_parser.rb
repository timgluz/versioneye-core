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
      dependency: Regexp.new( dependency_rule, Regexp::EXTENDED ),
      requires:   Regexp.new( require_keywords, Regexp::EXTENDED ),
      block_start: Regexp.new( block_start_rule, Regexp::EXTENDED | Regexp::IGNORECASE ),
      block_end:  Regexp.new( block_end_rule, Regexp::EXTENDED | Regexp::IGNORECASE )
    }
  end

  def parse(url)
    if url.to_s.empty?
      logger.error "CpanParser: url was empty"
      return nil
    end

    body = self.fetch_response_body(url)
    if body.to_s.empty?
      logger.error "CpanParser: got empty document from the #{url}"
      return nil
    end

    parse_content(body)
  end
  
  def parse_content(cpan_doc)
    return nil if cpan_doc.empty?

    project = init_project(url)
    deps = parse_dependencies cpan_doc
    parse_dependency_versions(project, deps)
    project.dep_number = project.projectdependencies.size
    project
  rescue => e
    log.error "CpanParser: error in parse_content. #{e.message} \n #{cpan_doc}"
    log.error e.backtrace.join('\n')
    nil
  end

  #parses dependency labels and checks outdated dependencies
  def parse_dependency_versions(project, deps)
    #TODO: finish
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

  def parse_line(current_scope, line)
    line = line.to_s.strip.gsub(/\'|\"/, '')
    if line.empty?
      return [current_scope, nil]
    end

    if (m = @rules[:requires])
      m = @rules[:dependency]
      dep = init_dependency(m[:package], m[:ranges], current_scope)
      [current_scope, dep]

    elsif (m = @rules[:block_start])
      [m[1].to_s.strip, nil]
    elsif (m = @rules[:block_end] )
      ['runtime', nil]
    else
      [current_scope, nil]
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

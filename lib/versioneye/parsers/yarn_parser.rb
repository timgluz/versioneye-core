require 'versioneye/parsers/common_parser'

class YarnParser < PackageParser
  attr_reader :rules

  def initialize
    # ATOMIC RULES
    numeric         = '\\d+'
    ident           = "\\w(\\w|-|\\.)*" # valid JS identifier
    prerelease_info = "\\-(?<prerelease>#{ident}[\\.#{ident}]*)" # matches release info: -alpha.1
    build_info      = "\\+(?<build>#{ident}[\\.#{ident}]*)"      # matches build info
    version         = "(?<version>[v|V]?(#{numeric})(\\.(#{numeric})(\\.(#{numeric}))*)?)" #matches more than m.m.p

    semver          = "(?<semver>#{version}(#{prerelease_info})?(#{build_info})?)"

    dep_item        = "(?<depname>#{ident})\\@(?<selector>.+?)[\\,|\:]"
    version_row     = "version\\s+\"#{semver}\""
    subdep_row      = "(?<depname>#{ident}+)\\s+\"(?<selector>.+?)\""

    @rules = {
      semver:       Regexp.new(semver, Regexp::EXTENDED),
      dep:          Regexp.new(dep_item, Regexp::EXTENDED),
      version_row:  Regexp.new(version_row, Regexp::EXTENDED),
      subdep_row:   Regexp.new(subdep_row, Regexp::EXTENDED)
    }
  end

  def parse_content( content, token = nil)
    content = content.to_s.strip
    return nil if content.empty?
    return nil if content.eql?('Not found')

    dep_items = parse_file_content content
    if dep_items.nil?
      log.error "Failed to parse file content from:\n#{content}"
      return
    end

    project = init_project({'name' => 'yarn.lock'})
    parse_dependencies(dep_items, project)

    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def parse_dependencies(dep_items, project)
    dep_items.each do |dep|
      parse_line(dep[:name], dep[:version], project)
    end
  end

  #parses dependencies from yarn.lock file and returns hash-map of dependency results
  def parse_file_content(text_content)
    deps = []
    isSubDep = false
    isOptionalDep = false

    dep = {}
    text_content.split(/\n|\r/).each do |line|
      line.strip!
      if ( m = line.match( rules[:dep] ) )
        dep_name = m[:depname]
        selector = m[:selector]

        deps << dep unless dep.empty? #save previous depenency item into collection
        #init a new dependency object
        dep = {
          name: dep_name,
          version: selector, #uses version selector only if there's no version row
          deps: [],
          optionalDeps: []
        }
        isSubDep = false
        isOptionalDep = false

      elsif ( m = line.match( rules[:version_row] ) )
        dep[:version] = m[:semver].to_s.strip

      elsif line.match /\Adependencies:/i
        isSubDep = true
        isOptionalDep = false

      elsif line.match /\AoptionalDependencies:/i
        isSubDep = false
        isOptionalDep = true

      elsif ( m = line.match(rules[:subdep_row]) )
        dep_name = m[:depname]
        selector = m[:selector]

        if isSubDep
          dep[:deps] << { name: dep_name, selector: selector }
        end

        if isOptionalDep
          dep[:optionalDeps] << { name: dep_name, selector: selector }
        end

      end
    end

    deps << dep unless dep.empty? #add latest item
    deps
  end

end

require 'versioneye/parsers/common_parser'

class PaketParser < CommonParser
  attr_reader :rules, :comperators

  def initialize
    #RULES for SEMVER
    numeric = '\\d+'
    ident = "[\\w-]" #identificator aka textual value
    prerelease_info = "\\-(?<prerelease>#{ident}[\\.#{ident}]*)" #matches release info: -alpha.1
    build_info = "\\+(?<build>#{ident}[\\.#{ident}]*)" #matches build info
    version = "(?<version>(#{numeric})(\\.(#{numeric})(\\.(#{numeric}))?)?)"
    semver = "#{version}(#{prerelease_info})?(#{build_info})?"
    empty_string  = "^\\s*$"  # "" "   "

    #TODO: checkout SemVer module included by GEMFILE
    @rules = {
      version: Regexp.new(version, Regexp::EXTENDED),
      semver: Regexp.new(semver, Regexp::EXTENDED),
      empty: Regexp.new(empty_string, Regexp::EXTENDED)
    }

    @comperators = Set.new ['~>', '==', '<=', '>=', '=', '<', '>']
  end

  def semver?(version_label)
    return false if version_label.nil?

    return true if rules[:semver].match(version_label)
    return true if rules[:version].match(version_label)
    return true if rules[:empty].match(version_label)
    return false
  end

  def comperator?(comperator)
    false if comperator.nil?
    comperators.include?(comperator)
  end


  def parse_doc(paket_doc)
    lines = paket_doc.split(/[\n\r]/)
    if lines.empty?
      log.error "PaketParser: got empty file"
    end

    deps = []
    current_group = '*'
    lines.each do |line| 
      new_group, parsed_dep = parse_line(current_group, line)
      current_group = new_group if current_group != new_group
      
      next if parsed_dep.nil?

      deps << parsed_dep
    end
  end

  def parse_line(current_group, line)
    tkns =  line.to_s.split( /\s+/ )
    return [current_group, group_doc] if tkns.empty?

    
    if tkns.count == 1 and tkns.first == '' and current_group != '*'
      return ['*', nil] #switch back to default group
    end

    tkns.shift if tkns.first = '' #remove empty string that caused by tabulation in groups
    
    source_id, pkg_id, comperator, version = tkns
    source_id.downcase!
    dep_dt = {
      group: current_group,
      source: source_id.downcase,
      prod_key: pkg_id,
      comperator: '*',
      version: '',
    }

    case source_id
    when 'group'
      new_group = pkg_id
      return [new_group, nil] #alert that change of group

    when 'nuget'
      if comperator?(comperator) and semver?(version)
        dep_dt[:comperator] = comperator
        dep_dt[:version] = version
      elsif semver?(comperator)
        dep_dt[:comperator] = '='
        dep_dt[:version] = comperator
      end
      
      return [current_group, dep_dt]
    
    when 'git'
      if comperator?(comperator) and version
        dep_dt[:comperator] = comperator
        dep_dt[:version] = version
      elsif comperator.to_s.count > 0
        dep_dt[:comperator] = '='
        dep_dt[:version] = comperator
      end
       
      return [current_group, dep_dt]
    when 'github'
      pkg_id, version = pkg_id.split(':')
      if version
        dep_dt[:prod_key]   = pkg_id
        dep_dt[:comperator] = '='
        dep_dt[:version]    = version
      end

      return [current_group, dep_dt]
    when 'gist'
      return [current_group, dep_dt]
    when 'http'
      return [current_group, dep_dt]
    else
      return [current_group, nil]
    end

  end
end

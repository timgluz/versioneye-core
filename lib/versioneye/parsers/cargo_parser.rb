require 'versioneye/parsers/common_parser'
require 'semverly'

# Parser for cargo.toml used in Rust projects.
# official doc: http://doc.crates.io/specifying-dependencies.html
# uses semver implementation: https://github.com/steveklabnik/semver-parser

class CargoParser < CommonParser
  FIXNUM_MAX = (2**(0.size * 8 -2) -1)

  def parse_requested_version(version, dependency, product)
    version = version.to_s.strip
    if version.empty? or ['*', 'X', 'x'].include?(version)
      log.error "#{product} version label is missing."
      dependency[:version_label] = version
      update_requested_with_current(dependency, product)
      return dependency
    end

    if product.nil?
      log.error "dependency #{dependency} has no product or its unknown"
      dependency[:version_requested] = version
      return dependency
    end

    if version[0] == '='
      version_label = version.gsub(/\=\s*/, '').to_s.strip
      version_db = product.versions.where(version: version_label).first
      unless version_db
        log.error "#{product} has no match for #{version_label}"
        update_requested_with_current(dependency, product)
        return dependency
      end

      dependency[:version_requested]   = version_label
      dependency[:version_label]       = version_label
      dependency[:comperator]          = '='

    elsif version =~ /\A<(?!\=)/
      version_label = version.gsub(/<\s*/, '').to_s.strip
      newest_version = VersionService.smaller_than(product.versions, version_label)
      dependency[:version_requested]  = newest_version.to_s
      dependency[:version_label]      = version_label
      dependency[:comperator]         = '<'

    elsif version =~ /\A<=/
      version_label = version.gsub(/<=\s*/, '').to_s.strip
      newest_version = VersionService.smaller_than_or_equal(product.versions, version_label)
      dependency[:version_requested]  = newest_version.to_s
      dependency[:version_label]      = version_label
      dependency[:comperator]         = '<='

    elsif version =~ /^(>=)/
      version_label = version.gsub(/>=\s*/, '').to_s.strip
      newest_version = VersionService.greater_than_or_equal(product.versions, version_label)
      dependency[:version_requested]  = newest_version.to_s
      dependency[:version_label]      = version_label
      dependency[:comperator]         = '>='

    elsif version =~ /\A>(?!\=)/
      version_label = version.gsub(/\>\s*/, '').to_s.strip
      newest_version = VersionService.greater_than(product.versions, version_label)
      dependency[:version_requested]  = newest_version.to_s
      dependency[:version_label]      = version_label
      dependency[:comperator]         = '>'

    elsif version[0] == '^' or is_semver(version)
      version_label = version.gsub(/\^\s*/, '').to_s.strip
      dependency[:version_requested]  = newest_caret_version(product.versions, version_label)
      dependency[:version_label]      = version_label
      dependency[:comperator]         = '^'

    elsif version[0] == '~'
      version_label = version.gsub(/\~\s*/, '').to_s.strip
      dependency[:version_requested]  = newest_tilde_version(product.versions, version_label)
      dependency[:version_label]      = version_label
      dependency[:comperator]         = '~'
    elsif version =~ /\.[\*|x|X]/
      dependency[:version_requested]  = newest_wildcard_version(product.versions, version)
      dependency[:version_label]      = version
      dependency[:comperator]         = '*'
    end

    dependency
  end

  def is_semver(version_label)
    !SemVer.parse(version_label.to_s).nil?
  end

  def newest_tilde_version(versions, version_label)
    lower_border = tilde_lower_border version_label
    upper_border = tilde_upper_border version_label

    if lower_border.nil? or upper_border.nil?
      return version_label
    end

    greater_than = VersionService.greater_than_or_equal versions, lower_border, true
    newest_version = VersionService.smaller_than(greater_than, upper_border)
    if newest_version
      newest_version
    else
      version_label
    end
  end

  def newest_caret_version(versions, version_label)
      lower_border = caret_lower_border version_label
      upper_border = caret_upper_border version_label
      if lower_border.nil? or upper_border.nil?
        return version_label
      end

      greater_than = VersionService.greater_than_or_equal versions, lower_border, true
      newest_version = VersionService.smaller_than(greater_than, upper_border)
      if newest_version
        newest_version
      else
        version_label
      end
  end

  def newest_wildcard_version(versions, version_label)
    lower_border = wildcard_lower_border version_label
    upper_border = wildcard_upper_border version_label
    if lower_border.nil? or upper_border.nil?
      return version_label
    end

    greater_than = VersionService.greater_than_or_equal versions, lower_border, true
    newest_version = VersionService.smaller_than(greater_than, upper_border)
    if newest_version
      newest_version
    else
      version_label
    end
  end

  # turns caret semver selector into lower version
  # returns:
  # nil - failed to parse semver
  # string - lower range of caret version
  def caret_lower_border(version_label)
    lower_ver = SemVer.parse version_label
    return nil if lower_ver.nil?
    #remove metdata details
    lower_ver.metadata = nil
    lower_ver.prerelease = nil

    lower_ver.to_s
  end

  # calculates upper version of caret semver
  # it increments most left-most non-zero value
  # returns:
  # nil - failed to parse semver
  # string - upper range of caret version
  def caret_upper_border(version_label)
    upper_ver = SemVer.parse version_label
    return nil if upper_ver.nil?

    #remove metdata and pre-release details
    upper_ver.metadata = nil
    upper_ver.prerelease = nil

    #increase left-most non-zero version item
    if upper_ver.major != 0
      upper_ver.major += 1
      upper_ver.minor = 0
      upper_ver.patch = 0
    elsif upper_ver.major == 0 and upper_ver.minor != 0
      upper_ver.minor += 1
      upper_ver.patch = 0
    else
      if upper_ver.patch != 0
        upper_ver.patch += 1
      else
        upper_ver.major += 1 #when version is '0.0.0'
      end
    end

    upper_ver.to_s
  end

  # finds the lower version for tilde selector
  # returns:
  #   nil - failed to parse semver
  #   string - lower border of tilde selector
  def tilde_lower_border(version_label)
    lower_ver =  SemVer.parse version_label
    return nil if lower_ver.nil?

    #remove metdata details
    lower_ver.metadata = nil
    lower_ver.prerelease = nil

    lower_ver.to_s
  end

  # finds the upper version of the tilde selector
  # it allows only changes in patch => has at least major, minor part
  # it allows only changes in minor => has only major part
  # returns:
  #   nil - failed to parse semver
  #   string - upper border of tilde selector
  def tilde_upper_border(version_label)
    upper_ver = SemVer.parse version_label
    return nil if upper_ver.nil?

    #remove metadata and prerelease details
    upper_ver.metadata = nil
    upper_ver.prerelease = nil

    if version_label =~ /^\d+\.\d+/
      upper_ver.minor += 1
      upper_ver.patch = 0
    else
      upper_ver.major += 1
      upper_ver.minor = 0
      upper_ver.patch = 0
    end

    upper_ver.to_s
  end

  # finds the lower version of the wildcard selector
  # replaces each * with 0
  def wildcard_lower_border(version_label)
    version = version_label.to_s.gsub(/\*+/, '0').to_s
    lower_ver = SemVer.parse version
    return nil if lower_ver.nil?

    #remove metadata and prerelease details
    lower_ver.metadata = nil
    lower_ver.prerelease = nil

    lower_ver.to_s
  end

  #finds the highest version of the wildcard selector
  # replaces each * with 0 and increments rightmost non-zero value
  def wildcard_upper_border(version_label)
    version = version_label.to_s.gsub(/\*+/, '0').to_s
    upper_ver = SemVer.parse version
    return nil if upper_ver.nil?

    #remove metadata and prerelease details
    upper_ver.metadata = nil
    upper_ver.prerelease = nil

    if version_label =~ /^\d+\.\d+\.[\*|x|X]/
      upper_ver.minor += 1
    elsif version_label =~ /^\d+\.[\*|x|X]/
      upper_ver.major += 1
    elsif version_label =~ /\*|x|X/
      upper_ver.major = FIXNUM_MAX #earliest rules should match this aka use latest version rule
    end

    upper_ver.to_s
  end
end

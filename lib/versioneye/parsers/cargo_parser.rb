require 'versioneye/parsers/common_parser'
require 'semverly'

# Parser for cargo.toml used in Rust projects.
# official doc: http://doc.crates.io/specifying-dependencies.html
# uses semver implementation: https://github.com/steveklabnik/semver-parser

class CargoParser < CommonParser

  def parse_requested_version(version, dependency, product)
    version = version.to_s.strip
    if version.empty?
      log.error "#{product} version label is missing."
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
    end

    dependency
  end

end

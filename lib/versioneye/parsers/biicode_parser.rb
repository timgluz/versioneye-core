require 'versioneye/parsers/common_parser'
require 'semverly'

class BiicodeParser < CommonParser


  # Parser for biicode.conf
  #
  def parse( url )
    return nil if url.to_s.empty?

    body = self.fetch_response_body( url )
    parse_content( body )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( content )
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    project = init_project
    section = ''
    content.each_line do |line|
      if line.strip.match(/\[\S*\]/i)
        section = line.strip.downcase
        next
      end
      if section.eql?('[requirements]') && !line.strip.empty?
        parse_line( line, project )
      end
    end
    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_line( line, project )
    return nil if line.to_s.empty?
    return nil if line.strip.match(/\A\#/) # skip comment lines

    owner      = nil
    block_name = nil
    track      = 'master'
    version    = nil

    short_match = line.match(/(\w*)\/(\w*)\s*\:\s*(-*\d)/i)
    if short_match
      owner      = short_match[1]
      block_name = short_match[2]
      version    = short_match[3]
    end

    long_match  = line.match(/(\w*)\/(\w*)\((\S*)\)\s*\:\s*(-*\d)/i)
    if long_match
      owner      = long_match[1]
      block_name = long_match[2]
      track      = long_match[3]
      version    = long_match[4]
    end

    return nil if short_match.nil? && long_match.nil?

    prod_key   = "#{owner}/#{owner}/#{block_name}/#{track}"
    product    = Product.fetch_product Product::A_LANGUAGE_BIICODE, prod_key
    dependency = init_dependency( product, prod_key )

    parse_requested_version( version, dependency, product )

    project.projectdependencies.push dependency
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 if product.nil?
    dependency
  end


  # It is important that this method is not writing into the database!
  def parse_requested_version(version_number, dependency, product)
    if version_number.to_s.empty?
      self.update_requested_with_current(dependency, product)
      return
    end

    if product.nil?
      dependency.comperator        = "="
      dependency.version_requested = version_number
      dependency.version_label     = version_number
      return
    end

    version = String.new( version_number )

    version.gsub!('=', '')
    version.gsub!(' ', '')
    dependency.version_requested = version
    dependency.version_label     = version
    dependency.comperator        = '='

    dependency
  end


  def init_project
    project = Project.new
    project.project_type = Project::A_TYPE_BIICODE
    project.language     = Product::A_LANGUAGE_BIICODE
    project.name         = 'biicode.conf'
    project
  end


  def init_dependency( product, name )
    dependency          = Projectdependency.new
    dependency.name     = name
    dependency.language = Product::A_LANGUAGE_BIICODE
    if product
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end


end

require 'versioneye/parsers/common_parser'
require 'versioneye/parsers/package_parser'
require 'semverly'

class BowerParser < PackageParser


  # http://bower.io/docs/creating-packages/#bowerjson
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


  def parse_content( content, token = nil )
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    data = JSON.parse( content )
    return nil if data.nil?

    project = init_project( data )

    dependencies = data['dependencies']
    if dependencies && !dependencies.empty?
      parse_dependencies dependencies, project
    end

    dependencies = data['devDependencies']
    if dependencies && !dependencies.empty?
      parse_dependencies dependencies, project, Dependency::A_SCOPE_DEVELOPMENT
    end

    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_dependencies dependencies, project, scope = Dependency::A_SCOPE_COMPILE
    dependencies.each do |package_name, version_label|
      parse_line( package_name.to_s.downcase, version_label, project, scope )
    end
  end


  def parse_line( package_name, version_label, project, scope = Dependency::A_SCOPE_COMPILE )

    alt_name = nil
    if version_label.match(/.+\#.+/)
      sps = version_label.split("#")
      version_label = sps[1]
      alt_name = sps[0]
    end

    product = Product.fetch_bower package_name
    if product.nil? && !alt_name.nil?
      product = Product.fetch_bower alt_name
    end

    dependency = init_dependency( product, package_name )
    dependency.scope = scope
    parse_requested_version( version_label, dependency, product )
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 if product.nil?
    project.projectdependencies.push dependency
  end


  def init_project( data )
    project = Project.new
    project.project_type = Project::A_TYPE_BOWER
    project.language     = Product::A_LANGUAGE_JAVASCRIPT
    project.name         = data['name']
    project.description  = data['description']
    project.version      = data['version']
    project
  end


  def init_dependency( product, name )
    dependency          = Projectdependency.new
    dependency.name     = name
    dependency.language = Product::A_LANGUAGE_JAVASCRIPT
    if product
      dependency.language        = product.language
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end


end

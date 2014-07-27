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
    log.error e.backtrace.join('\n')
    nil
  end


  def parse_content( content )
    data = JSON.parse( content )
    return nil if data.nil?

    dependencies = fetch_dependencies( data )
    return nil if dependencies.nil?

    project = init_project( data )
    dependencies.each do |package_name, version_label|
      parse_line( package_name.to_s.downcase, version_label, project )
    end
    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end


  def parse_line( package_name, version_label, project )
    product    = fetch_product package_name
    dependency = init_dependency( product, package_name )
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
    project
  end


  def fetch_dependencies( data )
    dependencies = data['dependencies']
    dev_dependencies = data['devDependencies'] #Shouldnt be separated?
    if dev_dependencies
      if dependencies.nil?
        dependencies = dev_dependencies
      else
        dependencies.merge!(dev_dependencies)
      end
    end
    dependencies
  end


  def fetch_product package_name
    name = package_name.downcase
    Product.where(prod_type: Project::A_TYPE_BOWER, name: name).first
  end


  def init_dependency( product, name )
    dependency          = Projectdependency.new
    dependency.name     = name
    dependency.language = Product::A_LANGUAGE_JAVASCRIPT # Not sure about that, it can be CSS as well !!

    if product
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end


end

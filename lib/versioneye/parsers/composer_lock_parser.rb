require 'versioneye/parsers/composer_parser'

class ComposerLockParser < ComposerParser

  def parse( url )
    return nil if url.to_s.empty?

    response = self.fetch_response( url )
    parse_content( response.body )
  end

  def parse_content( data )
    return nil if data.to_s.empty?

    content = JSON.parse( data )
    project = init_project

    dependencies = self.fetch_project_dependencies( content )
    if dependencies
      dependencies.each do |package|
        self.process_package project, package
      end
    end

    dependencies = self.fetch_project_dev_dependencies( content )
    if dependencies
      dependencies.each do |package|
        self.process_package project, package
      end
    end

    project.dep_number = project.dependencies.size
    project
  end

  def process_package project, package
    dependency = Projectdependency.new
    dependency.name = package['name']
    dependency.language = Product::A_LANGUAGE_PHP

    product = Product.fetch_product Product::A_LANGUAGE_PHP, dependency.name
    dependency.prod_key = product.prod_key if product

    version = self.fetch_package_version( package )
    self.parse_requested_version(version, dependency, product)

    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 unless product

    project.projectdependencies.push dependency
  end

  def fetch_package_version(package)
    return nil if package.nil? or package.empty? or not package.has_key?('version')
    version  = package['version']

    #if version string doesnt include any numbers, then look aliases
    unless version =~ /\d+/
      if package.has_key? 'extra' and package['extra'].has_key? 'branch-alias'
        aliases = package['extra']['branch-alias']
        alias_value = aliases[version]
        version = alias_value unless alias_value.nil?
      end
    end

    version.gsub! /^v/i, ''
    version
  end

  def fetch_project_dependencies( data )
    return nil if data.nil? || data['packages'].nil?
    data['packages']
  end

  def fetch_project_dev_dependencies( data )
    return nil if data.nil? || data['packages-dev'].nil?
    data['packages-dev']
  end

end

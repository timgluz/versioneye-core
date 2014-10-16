class SyncService < Versioneye::Service


  def self.sync
    Project.all.each do |project|
      handle_project project
    end
  end


  def self.handle_project project
    return if project.nil? || project.dependencies.empty?

    project.dependencies.each do |dep|
      handle_project_dep dep
    end
  end


  def self.handle_project_dep dependency
    return if dependency.nil?

    if dependency.unknown?
      check_for_update dependency
    end
  end


  def self.check_for_update dependency
    prod_key = dependency.name
    if dependency.group_id && dependency.artifact_id
      prod_key = "#{dependency.group_id}/dependency.artifact_id"
    end
    json = ProductClient.show dependency.language, prod_key
    return nil if json.to_s.empty?

    return nil if json["version"].eql?( dependency.version_requested )

    sync_product dependency.language, prod_key
  rescue => e
    p e.message
    log.error e.message
  end


  def self.sync_product language, prod_key
    json = ProductClient.versions language, prod_key
    json.deep_symbolize_keys!
    return if json[:versions].empty?

    json[:versions].each do |ver|
      sync_version language, prod_key, ver[:version]
    end
  end


  def self.sync_version language, prod_key, version
    json = ProductClient.show language, prod_key, version
    json.deep_symbolize_keys!

    create_product_if_not_exist json

    handle_licenses json
    handle_links json
    handle_archives json
    handle_dependencies json
  rescue => e
    log.error e.message
  end


  def self.create_product_if_not_exist json
    return nil if json.nil?

    product = Product.fetch_product json[:language], json[:prod_key]
    if product
      product.add_version json[:version], {:released_at => parsed_date(json[:released_at]) }
      product.save
      ProductService.update_newest_version product
      return
    end

    product = Product.new
    product.language      = json[:language]
    product.prod_key      = json[:prod_key]
    product.name          = json[:name]
    product.name_downcase = product.name.to_s.downcase
    product.prod_type     = json[:prod_type]
    product.version       = json[:version]
    product.group_id      = json[:group_id]
    product.artifact_id   = json[:artifact_id]
    product.description   = json[:description]
    product.save
    product.add_version json[:version], {:released_at => parsed_date(json[:released_at]) }
    product.save
    ProductService.update_newest_version product
  end


  def self.handle_licenses json
    return nil if json[:licenses].empty?

    json[:licenses].each do |license|
      license.deep_symbolize_keys!
      create_license_if_not_exist json, license[:name], license[:url]
    end
  rescue => e
    log.error e.message
  end


  def self.create_license_if_not_exist json, name, url
    language = json[:language]
    prod_key = json[:prod_key]
    version = json[:version]
    License.find_or_create language, prod_key, version, name, url
  end



  def self.handle_links json
    return nil if json[:links].empty?

    json[:links].each do |link|
      link.deep_symbolize_keys!
      create_link_if_not_exist json, link[:name], link[:link]
    end
  rescue => e
    log.error e.message
  end


  def self.create_link_if_not_exist json, name, link
    language = json[:language]
    prod_key = json[:prod_key]
    version = json[:version]
    Versionlink.create_versionlink language, prod_key, version, link, name
  end



  def self.handle_archives json
    return nil if json[:archives].empty?

    json[:archives].each do |archive|
      archive.deep_symbolize_keys!
      create_archive_if_not_exist json, archive[:name], archive[:link]
    end
  rescue => e
    log.error e.message
  end


  def self.create_archive_if_not_exist json, name, link
    language = json[:language]
    prod_key = json[:prod_key]
    version = json[:version]
    archive = Versionarchive.new({:language => language, :prod_key => prod_key, :version_id => version, :link => link, :name => name})
    Versionarchive.create_archive_if_not_exist archive
  end


  def self.handle_dependencies json
    return nil if json[:dependencies].empty?

    json[:dependencies].each do |dependency|
      dependency.deep_symbolize_keys!
      create_dependency_if_not_exist json, dependency
    end
  rescue => e
    log.error e.message
  end


  def self.create_dependency_if_not_exist json, dependency
    language = json[:language]
    prod_key = json[:prod_key]
    prod_version = json[:version]

    dep_prod_key = dependency[:dep_prod_key]
    dep_version = dependency[:version]

    dependencies = Dependency.where(language: language, prod_key: prod_key, prod_version: prod_version, dep_prod_key: dep_prod_key, version: dep_version)
    return nil if dependencies && dependencies.count > 0

    new_dep = Dependency.new({language: language, prod_key: prod_key, prod_version: prod_version, dep_prod_key: dep_prod_key, version: dep_version})
    new_dep.prod_type      = json[:prod_type]
    new_dep.scope          = dependency[:scope]
    new_dep.name           = dependency[:name]
    new_dep.group_id       = dependency[:group_id]
    new_dep.artifact_id    = dependency[:artifact_id]
    new_dep.parsed_version = dependency[:parsed_version]
    new_dep.save
    DependencyService.outdated? new_dep
  end


  private

    def self.parsed_date released_at
      DateTime.parse( released_at )
    rescue => e
      nil
    end


end

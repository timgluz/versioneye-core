class ProjectdependencyFactory

  def self.create_new(project, product, store = true, options = {})
    dependency = Projectdependency.new( options )
    if product
      dependency.name            = product.name
      dependency.language        = product.language
      dependency.prod_key        = product.prod_key
      dependency.group_id        = product.group_id
      dependency.artifact_id     = product.artifact_id
      dependency.version_current = product.version
      dependency.version_label   = product.version
    end
    if store
      dependency.save
    end
    project.projectdependencies.push dependency
    dependency
  end

end

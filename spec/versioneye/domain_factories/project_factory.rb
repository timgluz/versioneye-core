class ProjectFactory

  def self.create_new(user, extra_fields = nil, save = true, orga = nil)
    if user.nil? || user.to_s.empty?
      log.error "User was unspecified or empty."
    end

    project_data =  {
                      :user_id  =>  user.ids,
                      :name     => "test_project"
                    }

    unless extra_fields.nil?
      project_data.merge!(extra_fields)
    end

    new_project = Project.new project_data

    if orga
      new_project.organisation_id = orga.ids
    end

    if save
      unless new_project.save
        p new_project.errors.full_messages.to_sentence
      end
    end

    new_project
  end


  def self.default user, m = 1
    project = ProjectFactory.create_new user

    p1 = 1 * m
    p2 = 2 * m
    p3 = 3 * m
    prod_1  = ProductFactory.create_new p1
    prod_2  = ProductFactory.create_new p2
    prod_3  = ProductFactory.create_new p3

    dep_1 = ProjectdependencyFactory.create_new project, prod_1, true, {:version_requested => '1000.0.0'}
    dep_2 = ProjectdependencyFactory.create_new project, prod_2, true, {:version_requested => '0.0.0'}
    dep_3 = ProjectdependencyFactory.create_new project, prod_3, true, {:version_requested => '0.0.0'}

    project.dependencies.each do |dep|
      dep.save
    end

    project
  end

  def self.new_project user
    project = ProjectFactory.create_new user

    prod_4  = ProductFactory.create_new 4
    prod_5  = ProductFactory.create_new 5
    prod_6  = ProductFactory.create_new 6

    dep_4 = ProjectdependencyFactory.create_new project, prod_4, true, {:version_requested => '0.0.0'}
    dep_5 = ProjectdependencyFactory.create_new project, prod_5, true, {:version_requested => '0.0.0'}
    dep_6 = ProjectdependencyFactory.create_new project, prod_6, true, {:version_requested => '0.0.0'}

    project.dependencies.each do |dep|
      dep.save
    end

    project
  end

end

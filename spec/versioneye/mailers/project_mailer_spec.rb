require 'spec_helper'

describe ProjectMailer do

  describe 'projectnotification_email' do

    it 'should have 1 dependency' do
      user      = UserFactory.create_new
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      project   = ProjectFactory.create_new user
      project_dep_1 = Projectdependency.new({:language => product_1.language, :prod_key => product_1.prod_key, :project_id => project.id })
      project_dep_1.version_requested = '0.0.0'
      project_dep_1.version_label = '0.0.0'
      project_dep_1.save
      project_dep_2 = Projectdependency.new({:language => product_2.language, :prod_key => product_2.prod_key, :project_id => project.id })
      project_dep_2.version_requested = '100.100.100'
      project_dep_2.version_label = '100.100.100'
      project_dep_2.save

      email = described_class.projectnotification_email(project, user)

      email.to.should eq( [user.email]  )
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( 'for your project ' )
      email.encoded.should include( '?utm_medium=email' )
      email.encoded.should include( 'utm_source=project_notification' )
      email.encoded.should include( "/user/projects/#{project._id.to_s}" )
      email.encoded.should include( "Outdated Dependencies:" )
      email.encoded.should include( ">1<" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end


    it 'should have 2 dependency' do
      user      = UserFactory.create_new
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      project   = ProjectFactory.create_new user
      project_dep_1 = Projectdependency.new({:language => product_1.language, :prod_key => product_1.prod_key, :project_id => project.id, :name => product_1.name })
      project_dep_1.version_requested = '0.0.0'
      project_dep_1.version_label = '0.0.0'
      project_dep_1.save
      project_dep_2 = Projectdependency.new({:language => product_2.language, :prod_key => product_2.prod_key, :project_id => project.id, :name => product_2.name })
      project_dep_2.version_requested = '0.0.0'
      project_dep_2.version_label = '0.0.0'
      project_dep_2.save

      project.projectdependencies.count.should eq(2)
      deps = ProjectService.outdated_dependencies( project, true )
      deps.count.should eq(2)

      email = described_class.projectnotification_email(project, user)

      p "email.to: #{email.to}"

      email.to.should eq( [user.email] )
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( 'for your project ' )
      email.encoded.should include( '?utm_medium=email' )
      email.encoded.should include( 'utm_source=project_notification' )
      email.encoded.should include( "/user/projects/#{project._id.to_s}" )
      email.encoded.should include( "Outdated Dependencies:" )
      email.encoded.should include( ">2<" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end

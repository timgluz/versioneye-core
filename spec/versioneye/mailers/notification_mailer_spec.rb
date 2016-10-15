require 'spec_helper'

describe NotificationMailer do

  describe 'new_version_email' do

    it 'should have the title of the post' do
      Plan.create_defaults

      user = UserFactory.create_new
      expect( user.save ).to be_truthy
      notification = NotificationFactory.create_new user
      notifications = Notification.unsent_user_notifications user

      orga = OrganisationService.create_new_for user
      expect( orga.save ).to be_truthy

      product = notification.product

      project = ProjectFactory.create_new user, nil, true, orga
      expect( project.save ).to be_truthy

      project_dep = Projectdependency.new({:language => product.language, :prod_key => product.prod_key, :project_id => project.id })
      expect( project_dep.save ).to be_truthy

      email = NotificationMailer.new_version_email(user, notifications)

      expect( email.to ).to eq( [user.email] )
      expect( email.encoded ).to include( "Hello #{user.fullname}" )
      expect( email.encoded ).to include( 'There are new releases out there' )
      expect( email.encoded ).to include( '?utm_medium=email' )
      expect( email.encoded ).to include( 'utm_source=new_version' )
      expect( email.encoded ).to include( product.name )
      expect( email.encoded ).to include( notification.version_id )
      expect( email.encoded ).to include( "/user/projects/#{project.ids}" )
      expect( email.encoded ).to include( "http://localhost:3000" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      expect( ActionMailer::Base.deliveries.size ).to eq(1)
    end

  end

  describe 'status' do

    it 'should have the title of the post' do

      email = NotificationMailer.status(1000)

      expect( email.encoded ).to include( "Hey Admin Dude" )
      expect( email.encoded ).to include( 'Today we send out 1000 notification E-Mails' )
      expect( email.encoded ).to include( 'Your VersionEye Team' )
      expect( email.encoded ).to include( 'CEO' )
      expect( email.encoded ).to include( 'Robert Reiz' )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      expect( ActionMailer::Base.deliveries.size ).to eq(1)
    end

  end

end

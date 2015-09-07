require 'spec_helper'

describe SecurityNotificationService do


  describe 'procoess' do

    it 'sends out an email' do
      product = ProductFactory.create_for_composer 'symfony/symfony', '2.4.1'
      expect( product.save ).to be_truthy

      user    = UserFactory.create_new 1
      project = ProjectFactory.create_new user
      dep = ProjectdependencyFactory.create_new project, product
      dep.version_requested = '2.4.1'
      dep.save

      sv  = SecurityVulnerability.new({:language => product.language, :prod_key => product.prod_key})
      sv.summary = "Really really bad stuff!"
      sv.affected_versions = ['2.4.1']
      expect( sv.save ).to be_truthy

      product.versions.each do |version|
         version.sv_ids << sv.ids
      end
      product.save

      ProjectdependencyService.update_security project

      ActionMailer::Base.deliveries.clear
      expect( SecurityNotificationService.process_user( user.ids ) ).to be_truthy
      expect( ActionMailer::Base.deliveries.size).to eq(1)
      expect( MailTrack.count ).to eq(1)

      SecurityNotificationService.process

      expect( ActionMailer::Base.deliveries.size).to eq(1)
      expect( MailTrack.count ).to eq(1)
      expect( MailTrack.first.template ).to eq(MailTrack::A_TEMPLATE_PROJECT_SV)
    end

  end


  describe "process_user" do

   it 'returns nil because no user for id' do
      expect( SecurityNotificationService.process_user( 'NaV' ) ).to be_nil
   end

   it 'returns nil because user is deleted' do
      user = UserFactory.create_new 1
      user.deleted_user = true
      user.save
      expect( SecurityNotificationService.process_user( user.ids ) ).to be_nil
   end

   it 'returns nil because email is inactive' do
      user = UserFactory.create_new 1
      user.email_inactive = true
      user.save
      expect( SecurityNotificationService.process_user( user.ids ) ).to be_nil
   end

   it 'returns nil because of notifcation settings' do
      user = UserFactory.create_new 1
      uns = UserNotificationSetting.fetch_or_create_notification_setting( user )
      uns.project_emails = false
      uns.save
      expect( SecurityNotificationService.process_user( user.ids ) ).to be_nil
   end

   it 'returns nil because user has no vulnarable' do
      user = UserFactory.create_new 1
      expect( SecurityNotificationService.process_user( user.ids ) ).to be_nil
   end

  end

end

require 'spec_helper'

describe ProjectBatchUpdateService do


  describe 'update_all' do

    it 'updates a project' do
      product = ProductFactory.create_for_cocoapods 'JSONKit', '2.0.0'
      expect( product.save ).to be_truthy

      user    = UserFactory.create_new 1

      parser  = PodfileParser.new
      project = parser.parse_file './spec/fixtures/files/pod_file/example1/Podfile'
      project.name = 'Podfile'
      project.make_project_key!
      project.user_id = user.ids
      project.period = Project::A_PERIOD_DAILY
      project.sum_own!
      expect( project.save ).to be_truthy
      expect( project.out_number ).to be > 0
      expect( project.out_number_sum ).to be > 0

      ActionMailer::Base.deliveries.clear
      ProjectBatchUpdateService.update_all Project::A_PERIOD_DAILY
      ActionMailer::Base.deliveries.size.should == 1
      expect(MailTrack.send_already?(user.ids, ProjectBatchUpdateService::A_EMAIL_TEMPLATE_1, project.period)).to be_truthy
      expect(MailTrack.count).to eq(1)
      ProjectBatchUpdateService.update_all Project::A_PERIOD_DAILY
      expect(MailTrack.count).to eq(1)
      ActionMailer::Base.deliveries.size.should == 1
    end

    it 'doesnt send out email because project is up-to-date' do
      user    = UserFactory.create_new 1

      parser  = PodfileParser.new
      project = parser.parse_file './spec/fixtures/files/pod_file/example1/Podfile'
      project.name = 'Podfile'
      project.make_project_key!
      project.user_id = user.ids
      project.period = Project::A_PERIOD_DAILY
      project.sum_own!
      expect( project.save ).to be_truthy
      expect( project.out_number_sum ).to eq(0)

      ActionMailer::Base.deliveries.clear
      ProjectBatchUpdateService.update_all Project::A_PERIOD_DAILY
      expect( ActionMailer::Base.deliveries.size ).to eq(0)
    end

    it 'doesnt send out email because project violates license whitelist' do
      product = ProductFactory.create_for_cocoapods 'JSONKit', '1.1.0'
      expect( product.save ).to be_truthy
      LicenseFactory.create_new product, 'GPL'

      user = UserFactory.create_new 1

      LicenseWhitelistService.create user, 'SuperList'
      LicenseWhitelistService.add user, 'SuperList', 'MIT'
      lwl = LicenseWhitelistService.fetch_by user, 'SuperList'

      parser  = PodfileParser.new
      project = parser.parse_file './spec/fixtures/files/pod_file/example1/Podfile'
      project.name = 'Podfile'
      project.make_project_key!
      project.user_id = user.ids
      project.license_whitelist_id = lwl.ids
      project.period = Project::A_PERIOD_DAILY
      ProjectService.update_license_numbers!( project )
      project.sum_own!
      expect( project.save ).to be_truthy
      expect( project.out_number ).to eq(0)
      expect( project.out_number_sum ).to eq(0)
      expect( project.licenses_red ).to eq(1)
      expect( project.licenses_red_sum ).to eq(1)

      ActionMailer::Base.deliveries.clear
      ProjectBatchUpdateService.update_all Project::A_PERIOD_DAILY
      expect( ActionMailer::Base.deliveries.size ).to eq(1)
    end

    it 'sends out email because child project is out-dated' do
      product = ProductFactory.create_for_gemfile('rails', '4.0.0')
      product.save

      user    = UserFactory.create_new 1

      parser  = PodfileParser.new
      project = parser.parse_file './spec/fixtures/files/pod_file/example1/Podfile'
      project.name = 'Podfile'
      project.make_project_key!
      project.user_id = user.ids
      project.period = Project::A_PERIOD_DAILY
      project.save

      gemfile = "spec/fixtures/files/Gemfile"
      file = File.open(gemfile, "rb")
      content = file.read
      parser = GemfileParser.new
      project_2 = parser.parse_content content
      project_2.name = 'Gemfile'
      project_2.make_project_key!
      project_2.user_id = user.ids
      project_2.period = Project::A_PERIOD_DAILY
      project_2.save

      project_2.parent_id = project.ids
      project_2.save

      ActionMailer::Base.deliveries.clear
      ProjectBatchUpdateService.update_all Project::A_PERIOD_DAILY
      expect( ActionMailer::Base.deliveries.size ).to eq(1)

      project.reload
      expect( project.out_number_sum ).to eq(1) # It's 1 because child project has 1 out-dated dependency
    end

    it 'sends out 2 emails because of collaboration project' do
      product = ProductFactory.create_for_cocoapods 'JSONKit', '2.0.0'
      expect( product.save ).to be_truthy

      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024

      parser  = PodfileParser.new
      project = parser.parse_file './spec/fixtures/files/pod_file/example1/Podfile'
      project.name = 'Podfile'
      project.make_project_key!
      project.user_id = owner.ids
      project.period = Project::A_PERIOD_DAILY
      project.sum_own!
      expect( project.save ).to be_truthy
      expect( project.out_number_sum ).to eq(1)
      expect( project.licenses_red_sum ).to eq(0)

      collaborator = ProjectCollaborator.new(:project_id => 'NaN',
                                             :owner_id => owner._id,
                                             :caller_id => owner._id,
                                             :user_id => user._id,
                                             :period => Project::A_PERIOD_DAILY )
      expect( collaborator.save ).to be_truthy

      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :caller_id => owner._id,
                                             :user_id => user._id,
                                             :period => Project::A_PERIOD_DAILY )
      expect( collaborator.save ).to be_truthy
      project.collaborators << collaborator
      expect( project.save ).to be_truthy

      ActionMailer::Base.deliveries.clear
      project_ids = ProjectBatchUpdateService.update_all Project::A_PERIOD_DAILY
      expect( project_ids.count ).to eq(1)
      expect( ActionMailer::Base.deliveries.size ).to eq(2)
      expect( ProjectCollaborator.count ).to eq(1)
    end

  end

end

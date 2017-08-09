require 'spec_helper'

describe TeamNotificationService do


  before(:each) do
    Plan.create_defaults
    @user = User.new({:fullname => 'Hans Tanz', :username => 'hanstanz',
      :email => 'hans@tanz.de', :password => 'password', :salt => 'salt',
      :terms => true, :datenerhebung => true})
    @user.save
    @orga = OrganisationService.create_new_for @user
    expect( @orga.save ).to be_truthy
  end


  describe "process_teams" do

    it "sends out 0 emails because projects are not affected" do
      @orga.plan = Plan.micro
      expect( @orga.save ).to be_truthy
      team = Team.new({:name => 'devs', :organisation_id => @orga.ids })
      expect( team.save ).to be_truthy
      expect( team.add_member(@user) ).to be_truthy
      expect( TeamMember.count ).to eq(2)
      expect( Team.count ).to eq(2)

      project1 = ProjectFactory.create_new @user
      project1.organisation_id = @orga.ids
      project1.teams << team
      expect( project1.save ).to be_truthy
      expect( project1.teams ).to_not be_empty

      ActionMailer::Base.deliveries.clear
      TeamNotificationService.process_team @orga, team
      ActionMailer::Base.deliveries.size.should == 0

      project1.sv_count_sum = 1
      expect( project1.save ).to be_truthy

      ActionMailer::Base.deliveries.clear
      TeamNotificationService.process_team @orga, team
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end

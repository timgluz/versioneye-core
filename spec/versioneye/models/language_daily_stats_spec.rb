require 'spec_helper'

describe LanguageDailyStats do

  def create_today_products
    newests = []
    (0..12).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      name = "#{name}_#{s}"
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby',
        :prod_type => 'gem', :version => Random.rand(1..99),
        created_at: Date.today })
      newest.save
      newests << newest
    end
    newests
  end

  def create_yesterday_products
    newests = []
    (20..36).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      name = "#{name}_#{s}"
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby',
        :prod_type => 'gem', :version => Random.rand(1..99),
        created_at: 1.days.ago.at_midnight })
      newest.save
      newests << newest
    end
    newests
  end

  def create_lastweek_products
    newests = []
    (40..58).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      name = "#{name}_#{s}"
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby',
        :prod_type => 'gem', :version => Random.rand(1..99),
        created_at: 7.days.ago.at_midnight })
      newest.save
      newests << newest
    end
    newests
  end

  def create_lastmonth_products
    newests = []
    (100..122).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      name = "#{name}_#{s}"
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby',
        :prod_type => 'gem', :version => Random.rand(1..99),
        created_at: (Date.today << 1).at_midnight })
      newest.save
      newests << newest
    end
    newests
  end

  def create_twomonth_products
    newests = []
    (1000..1028).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      name = "#{name}_#{s}"
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby',
        :prod_type => 'gem', :version => Random.rand(1..99),
        created_at: (Date.today << 2).at_midnight })
      newest.save
      newests << newest
    end
    newests
  end

  let(:today_ruby_products){
    FactoryGirl.create_list(:newest, 13,
                             name: FactoryGirl.generate(:product_name_generator),
                             prod_key: FactoryGirl.generate(:product_name_generator),
                             language: "Ruby",
                             version: FactoryGirl.generate(:version_generator),
                             created_at: Date.today.at_midnight)}

  let(:yesterday_ruby_products){
    FactoryGirl.create_list(:newest, 17,
                             name: FactoryGirl.generate(:product_name_generator),
                             prod_key: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             language: "Ruby",
                             created_at: 1.days.ago.at_midnight)}

  let(:lastweek_ruby_products){
    FactoryGirl.create_list(:newest, 19,
                             name: FactoryGirl.generate(:product_name_generator),
                             prod_key: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             language: "Ruby",
                             created_at: 7.days.ago.at_midnight)}

  let(:lastmonth_ruby_products){
    FactoryGirl.create_list(:newest, 23,
                             name: FactoryGirl.generate(:product_name_generator),
                             prod_key: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             language: "Ruby",
                             created_at: (Date.today << 1).at_midnight)}

  let(:twomonth_ruby_products){
    FactoryGirl.create_list(:newest, 29,
                             name: FactoryGirl.generate(:product_name_generator),
                             prod_key: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             language: "Ruby",
                             created_at: (Date.today << 2).at_midnight)}

  after :each do
    LanguageDailyStats.delete_all
  end

  describe "today_stats" do
    before :each do
      create_today_products
    end

   it "should return all ruby project" do
      Newest.all.count.should eq(13)
      LanguageDailyStats.all.count.should eq(0)
      LanguageDailyStats.update_counts
      LanguageDailyStats.all.count.should eq(1)
      p "count: #{LanguageDailyStats.all.count}"
      stats = LanguageDailyStats.today_stats
      stats.should_not be_nil
      p "stats: #{stats}"
      stats.has_key?('Ruby').should be_truthy
      stats['Ruby'].has_key?("new_version")
      stats['Ruby']["new_version"].should eq(13)
    end

    #important! It catches double counting today
    it "shoulnt double count today's metrics" do
      create_yesterday_products
      create_twomonth_products
      LanguageDailyStats.update_counts(61)

      stats = LanguageDailyStats.today_stats
      stats.should_not be_nil
      stats.count.should > 0
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(13)

    end
  end

  describe "yesterday_stats" do
    before :each do
      create_today_products
      create_yesterday_products
      LanguageDailyStats.update_counts(2)
    end

    after :each do
      LanguageDailyStats.delete_all
    end


    it "should return all ruby project" do
      stats = LanguageDailyStats.yesterday_stats

      stats.should_not be_nil
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(17)
    end
  end

  describe "current_week_stats" do
    before :each do
      create_today_products
      create_yesterday_products
      LanguageDailyStats.update_counts(3)
    end

    it "should return correct stats for current week" do
      stats =  LanguageDailyStats.current_week_stats

      stats.should_not be_nil
      stats.empty?.should be_falsey
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      if Time.now.monday?
        # yesterday was Sunday, that's last week
        stats["Ruby"]["new_version"].should eq(13)
      else
        stats["Ruby"]["new_version"].should eq(30)
      end
    end
  end

  describe "last_week_stats" do
    before :each do
      create_lastweek_products
      LanguageDailyStats.update_counts(14)
    end

    it "should return correct stats for last week" do
      stats = LanguageDailyStats.last_week_stats

      stats.should_not be_nil
      stats.empty?.should be_falsey
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(19)
    end
  end

  describe "current_month_stats" do
    before :each do
      @total_counts = 13
      create_today_products
      if Date.today.day > 1
        create_yesterday_products
        @total_counts += 17
      end
      if Date.today.day > 7
        create_lastweek_products
        @total_counts += 19
      end
      LanguageDailyStats.update_counts(15)
    end

    it "should return correct stats for current month" do
      stats =  LanguageDailyStats.current_month_stats

      stats.should_not be_nil
      stats.empty?.should be_falsey
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(@total_counts)
    end
  end

  describe "last_month_stats" do
    before :each do
      create_lastmonth_products
      LanguageDailyStats.update_counts(32)
    end

    it "should return correct stats for last month" do
      stats =  LanguageDailyStats.last_month_stats

      stats.should_not be_nil
      stats.empty?.should be_falsey
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(23)
    end
  end

  describe "two_months_ago_stats" do
    before :each do
      create_twomonth_products
      LanguageDailyStats.update_counts(64)
    end

    it "should return correct stats for two month ago" do
      stats =  LanguageDailyStats.two_months_ago_stats

      stats.should_not be_nil
      stats.empty?.should be_falsey
      stats.has_key?("Ruby").should be_truthy
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(29)
    end
  end

  describe "count_artifacts" do
    it 'returns all artifacts' do
      prod = ProductFactory.create_new 1
      version = prod.version
      prod.remove_version( version )
      prod.add_version("10.10.10")
      prod.add_version("11.11.11")
      prod.save

      # This is 2 days in the Future
      after_tomorrow = prod.versions.first.created_at + 2.days
      p "after_tomorrow: #{after_tomorrow}"
      version = Version.new({:version => '1.1.1', :created_at => after_tomorrow, :updated_at => after_tomorrow })
      prod.versions.push version
      prod.save

      prod.versions.count.should eq(3)

      that_day = prod.created_at
      vals = LanguageDailyStats.count_artifacts(prod.language, that_day)
      vals.should eq(3) # Found only 2 because 3rd is in future!
    end
  end

end

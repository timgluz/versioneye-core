require 'spec_helper'

describe GlobalSetting do

  describe 'set' do

    it 'saves a new object' do
      GlobalSetting.count.should == 0
      described_class.set('test', 'SERVER_URL', 'http://localhost:8080').should be_true
      GlobalSetting.count.should == 1
    end

    it 'saves the object once' do
      GlobalSetting.count.should == 0
      described_class.set('test', 'SERVER_URL', 'http://localhost:8080').should be_true
      GlobalSetting.count.should == 1
      described_class.set('test', 'SERVER_URL', 'http://localhost:8080').should be_true
      GlobalSetting.count.should == 1
    end

    it 'changes the object' do
      GlobalSetting.count.should == 0
      described_class.set('test', 'SERVER_URL', 'http://localhost:8080').should be_true
      GlobalSetting.count.should == 1
      GlobalSetting.new.set('test', 'SERVER_URL', 'www.heise.de').should be_true
      GlobalSetting.count.should == 1
      GlobalSetting.first.value.should eq('www.heise.de')
    end

    it 'removes the object' do
      GlobalSetting.count.should == 0
      described_class.set('test', 'SERVER_URL', 'http://localhost:8080').should be_true
      GlobalSetting.count.should == 1
      described_class.set('test', 'SERVER_URL', nil).should be_true
      GlobalSetting.count.should == 0
    end

  end

  describe 'get' do

    it 'returns the right value' do
      gs = described_class.new(:environment => 'test', :key => 'SERVER_URL', :value => 'http://localhost:8080')
      gs.save.should be_true
      described_class.get('test', 'SERVER_URL').should eq('http://localhost:8080')
      gs.get('test', 'SERVER_URL').should eq('http://localhost:8080')
    end

  end

  describe 'keys' do

    it 'returns the keys' do
      described_class.new(:environment => 'test', :key => 'SERVER_URL',  :value => 'http://localhost:8080').save.should be_true
      described_class.new(:environment => 'test', :key => 'SERVER_PORT', :value => '8080').save.should be_true
      keys = described_class.keys('test')
      keys.should_not be_nil
      keys.count.should == 2
      keys = described_class.new.keys('test')
      keys.count.should == 2
    end

  end

  describe 'to_s' do

    it 'returns the to_s value' do
      gs = GlobalSetting.new({:environment => 'test', :key => 'hal', :value => 'lo'})
      gs.to_s.should eq('test : hal : lo')
    end

  end

end

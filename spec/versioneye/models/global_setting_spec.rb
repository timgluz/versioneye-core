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
      described_class.set('test', 'SERVER_URL', 'www.heise.de').should be_true
      GlobalSetting.count.should == 1
      GlobalSetting.first.value.should eq('www.heise.de')
    end

  end

  describe 'get' do

    it 'returns the right value' do
      gs = described_class.new(:environment => 'test', :key => 'SERVER_URL', :value => 'http://localhost:8080').save.should be_true
      described_class.get('test', 'SERVER_URL').should eq('http://localhost:8080')
    end

  end

end

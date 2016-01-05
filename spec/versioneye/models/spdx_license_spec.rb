require 'spec_helper'

describe SpdxLicense do


  describe 'identifier_by_fullname_regex' do

    it 'returns the right spdx object' do
      SpdxLicense.new({:fullname => "MIT", :identifier => 'mit'}).save
      spdx = described_class.identifier_by_fullname_regex('MIT')
      spdx.should_not be_nil
      spdx.identifier.should eq('mit')
    end

    it 'returns nil because of error' do
      SpdxLicense.new({:fullname => "MIT", :identifier => 'mit'}).save
      spdx = described_class.identifier_by_fullname_regex('MIT (')
      spdx.should be_nil
    end

  end


  describe 'identifier_by_regex' do

    it 'returns the right spdx object' do
      SpdxLicense.new({:fullname => "MIT", :identifier => 'mit'}).save
      spdx = described_class.identifier_by_regex('mit')
      spdx.should_not be_nil
      spdx.identifier.should eq('mit')
    end

    it 'returns nil because of error' do
      SpdxLicense.new({:fullname => "MIT", :identifier => 'mit'}).save
      spdx = described_class.identifier_by_regex('mit (')
      spdx.should be_nil
    end

  end


end

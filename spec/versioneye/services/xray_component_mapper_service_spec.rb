require 'spec_helper'

describe XrayComponentMapperService do


  describe "get_component_id" do

    it 'return nil because product is nil' do
      expect( described_class.get_component_id nil, "1" ).to be_nil
    end
    it 'return nil because version is nil' do
      product = Product.new :artifact_id => 'co'
      expect( described_class.get_component_id product, nil ).to be_nil
    end
    it 'return nil because group_id is nil' do
      product = Product.new :artifact_id => 'co'
      expect( described_class.get_component_id product, '1' ).to be_nil
    end
    it 'return nil because artifact_id is nil' do
      product = Product.new :group_id => 'co'
      expect( described_class.get_component_id product, '1' ).to be_nil
    end
    it 'return the component_id' do
      product = Product.new :group_id => 'commons-beanutils', :artifact_id => 'commons-beanutils', :prod_type => Project::A_TYPE_MAVEN2
      expect( described_class.get_component_id product, '1.9.1' ).to eq('gav://commons-beanutils:commons-beanutils:1.9.1')
    end
    it 'return nil because prod_type is not set' do
      product = Product.new :group_id => 'commons-beanutils', :artifact_id => 'commons-beanutils'
      expect( described_class.get_component_id product, '1.9.1' ).to be_nil
    end

  end


  describe "get_hash" do

    it 'returns the hash value' do
      product = Product.new :group_id => 'commons-beanutils', :artifact_id => 'commons-beanutils', :prod_type => Project::A_TYPE_MAVEN2
      comp_id = described_class.get_component_id( product, '1.9.1' )
      hash    = described_class.get_hash( comp_id, 'http://xrayintegration:8000/api/v1/componentMapper' )
      expect( hash ).to_not be_nil
      expect( hash['Blobs'][0] ).to eql('3ff09a693a5c11cf7727f354901329f5128f078292bdf1bfd6d19a605e902bb6')
    end

  end


end

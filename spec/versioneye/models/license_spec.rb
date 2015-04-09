require 'spec_helper'

describe License do

  describe 'to_s' do

    it 'returns the right to_s string' do
      license = License.new({:language => 'Ruby', :prod_key => 'rails',
        :version => '1.0.0', :name => 'MIT'})
      license.to_s.should eq('[License for (Ruby/rails/1.0.0) : MIT]')
    end

  end

  describe 'find_or_create' do

    it 'creates a new one' do
      License.count.should == 0
      described_class.find_or_create("PHP", "doctrine/doctrine", "1.0.0", "MIT").should_not be_nil
      License.count.should == 1
    end

    it 'creates a new one and returns it the 2nd time' do
      License.count.should == 0
      described_class.find_or_create("PHP", "doctrine/doctrine", "1.0.0", "MIT").should_not be_nil
      License.count.should == 1
      described_class.find_or_create("PHP", "doctrine/doctrine", "1.0.0", "MIT").should_not be_nil
      License.count.should == 1
    end

  end

  describe 'product' do

    it 'returns the product' do
      product = ProductFactory.create_new 1
      mit_license = LicenseFactory.create_new product, "MIT"
      prod = mit_license.product
      prod.id.to_s.should eq( product.id.to_s )
    end

  end

  describe 'for_product' do

    it 'returns the licenses for product' do
      product = ProductFactory.create_new 1
      mit_license = LicenseFactory.create_new product, "MIT"
      bsd_license = LicenseFactory.create_new product, "BSD"
      licenses = License.for_product product
      licenses.should_not be_nil
      licenses.count.should eq(2)
    end

    it 'returns the licenses for product' do
      product = ProductFactory.create_new 1
      mit_license = LicenseFactory.create_new product, "MIT"
      product.version = "not_1"
      bsd_license = LicenseFactory.create_new product, "BSD"
      licenses = License.for_product product
      licenses.should_not be_nil
      licenses.count.should eq(1)
      licenses.first.name.should eq('BSD')
      licenses = License.for_product product, true
      licenses.should_not be_nil
      licenses.count.should eq(2)
    end

  end

  describe "link" do

    it "should return mit link" do
      license = License.new({:name => "MIT"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return mit link" do
      license = License.new({:name => "mit"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return mit link" do
      license = License.new({:name => "The MIT License"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return mit link" do
      license = License.new({:name => "MIT License"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "The Apache Software License, Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return json link" do
      license = License.new({:name => "the json licensE"})
      license.link.should eq("http://www.json.org/license.html")
    end
    it "should return cddl 1.0 link" do
      license = License.new({:name => "Common Development and Distribution License 1.0"})
      license.link.should eq("http://spdx.org/licenses/CDDL-1.0.html")
    end
    it "should return cddl 1.0 link" do
      license = License.new({:name => "Common Development and Distribution License 1.1"})
      license.link.should eq("http://spdx.org/licenses/CDDL-1.1.html")
    end

  end

  describe "name_substitute" do

    it "should return MIT name" do
      license = License.new({:name => "MIT"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "MIT License"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "The MIT License"})
      license.name_substitute.should eq("MIT")
    end

    it "should return BSD name" do
      license = License.new({:name => "BSD"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "BSD License"})
      license.name_substitute.should eq("BSD")
    end

    it "should return BSD 2-Clause name" do
      license = License.new({:name => "The BSD 2 clause"})
      license.name_substitute.should eq("BSD 2-clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "The BSD 2 clause revised license"})
      license.name_substitute.should eq("BSD 2-clause")
    end

    it "should return BSD 3-Clause name" do
      license = License.new({:name => "The BSD 3-clause"})
      license.name_substitute.should eq("BSD 3-clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "The BSD 3 clause revised license"})
      license.name_substitute.should eq("BSD 3-clause")
    end

    it "should return Ruby name" do
      license = License.new({:name => "Ruby"})
      license.name_substitute.should eq("Ruby")
    end
    it "should return Ruby name" do
      license = License.new({:name => "Ruby License"})
      license.name_substitute.should eq("Ruby")
    end

    it "should return GPL 1.0 name" do
      license = License.new({:name => "GNU General Public License v1.0 only"})
      license.name_substitute.should eq("GPL-1.0")
    end
    it "should return GPL 1.0 name" do
      license = License.new({:name => "GPL 1"})
      license.name_substitute.should eq("GPL-1.0")
    end


    it "should return GPL 2.0 name" do
      license = License.new({:name => "GPL 2"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GPL-2"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GPL 2.0"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GNU General Public License v2.0 only"})
      license.name_substitute.should eq("GPL-2.0")
    end

    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU General Public License v3.0 only"})
      license.name_substitute.should eq("GPL-3.0")
    end

    it "should return LGPL 2.1 name" do
      license = License.new({:name => "GNU Lesser General Public License v2.1 only"})
      license.name_substitute.should eq("LGPL-2.1")
    end

    it "should return LGPL 3.0 name" do
      license = License.new({:name => "GNU Lesser General Public License v3.0 only"})
      license.name_substitute.should eq("LGPL-3.0")
    end

    it "should return AGPL 3.0 name" do
      license = License.new({:name => "GNU AFFERO GENERAL PUBLIC LICENSE Version 3"})
      license.name_substitute.should eq("AGPL-3.0")
    end
    it "should return AGPL 3.0 name" do
      license = License.new({:name => "AGPL 3.0"})
      license.name_substitute.should eq("AGPL-3.0")
    end

    it "should return Apache License version 2 name" do
      license = License.new({:name => "The Apache Software License\, Version 2\.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache-2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end

    it "should return Apache License name" do
      license = License.new({:name => "Apache License"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Software License"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "the Apache License, ASL Version 2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end

    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse"})
      license.name_substitute.should eq("EPL-1.0")
    end
    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse License"})
      license.name_substitute.should eq("EPL-1.0")
    end
    it "should return eclipse public license name" do
      license = License.new({:name => "EPL-1.0"})
      license.name_substitute.should eq("EPL-1.0")
    end
    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse Public License 1.0"})
      license.name_substitute.should eq("EPL-1.0")
    end

    it "should return Artistic-1.0 license name" do
      license = License.new({:name => "Artistic 1.0"})
      license.name_substitute.should eq("Artistic-1.0")
    end
    it "should return Artistic-1.0 license name" do
      license = License.new({:name => "Artistic License"})
      license.name_substitute.should eq("Artistic-1.0")
    end
    it "should return Artistic-1.0 license name" do
      license = License.new({:name => "Artistic-1.0"})
      license.name_substitute.should eq("Artistic-1.0")
    end

    it "should return Artistic-2.0 license name" do
      license = License.new({:name => "Artistic 2.0"})
      license.name_substitute.should eq("Artistic-2.0")
    end
    it "should return Artistic-2.0 license name" do
      license = License.new({:name => "Artistic-2.0"})
      license.name_substitute.should eq("Artistic-2.0")
    end

    it "should return the given name if name is uknown" do
      license = License.new({:name => "not_existing"})
      license.name_substitute.should eq("not_existing")
    end

    it "check for JSON license" do
      license = License.new({:name => "The JSON LiCense"})
      license.name_substitute.should eq("JSON")
    end
    it "check for JSON license" do
      license = License.new({:name => "JSON LiCense"})
      license.name_substitute.should eq("JSON")
    end

    it "check for CDDL 1.0 license" do
      license = License.new({:name => "Common Development and Distribution License 1.0"})
      license.name_substitute.should eq("CDDL-1.0")
    end

    it "check Zlib" do
      license = License.new({:name => "ZLIB license"})
      license.name_substitute.should eq("ZLIB license")
      spdx = SpdxLicense.new({:fullname => 'zlib License', :identifier => 'Zlib'})
      spdx.save 
      license.name_substitute.should eq("Zlib")
    end

  end

end

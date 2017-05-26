require 'spec_helper'

describe License do

  describe 'to_s' do

    it 'returns the right to_s string' do
      license = License.new({:language => 'Ruby', :prod_key => 'rails',
        :version => '1.0.0', :name => 'MIT'})
      license.to_s.should eq('[License for (Ruby/rails/1.0.0) : MIT]')
    end

  end

  describe 'label' do

    it 'returns the spdx_id' do
      license = License.new({:spdx_id => 'MIT', :name => ''})
      expect( license.label ).to eq("MIT")
    end

    it 'returns the spdx_id identifier' do
      license = License.new({:spdx_id => '', :name => 'MIT'})
      expect( license.label ).to eq("MIT")
    end

    it 'returns the spdx_id identifier because URL is set' do
      license = License.new({:spdx_id => '', :name => 'MIT', :url => 'https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt'})
      expect( license.label ).to eq("LGPL-2.1")
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

  describe "equals_id?" do

    it "is equal for LGPL-2.0+" do
      expect( License.new(:name => 'LGPL-2.0+').equals_id?('LGPL-2.0') ).to be_truthy
    end
    it "is equal for LGPL-2.0+" do
      expect( License.new(:name => 'LGPL-2.0+').equals_id?('LGPL-2.0+') ).to be_truthy
    end
    it "is equal for LGPL-2.0+" do
      expect( License.new(:name => 'LGPL-2.0+').equals_id?('LGPL-2.1') ).to be_truthy
    end
    it "is equal for LGPL-2.0+" do
      expect( License.new(:name => 'LGPL-2.0+').equals_id?('LGPL-2.1+') ).to be_truthy
    end
    it "is equal for LGPL-2.0+" do
      expect( License.new(:name => 'LGPL-2.0+').equals_id?('LGPL-3.0') ).to be_truthy
    end
    it "is equal for LGPL-2.0+" do
      expect( License.new(:name => 'LGPL-2.0+').equals_id?('LGPL-3.0+') ).to be_truthy
    end

    it "is equal for LGPL-2.1+" do
      expect( License.new(:name => 'LGPL-2.1+').equals_id?('LGPL-2.0') ).to be_falsey
    end
    it "is equal for LGPL-2.1+" do
      expect( License.new(:name => 'LGPL-2.1+').equals_id?('LGPL-2.0+') ).to be_falsey
    end
    it "is equal for LGPL-2.1+" do
      expect( License.new(:name => 'LGPL-2.1+').equals_id?('LGPL-2.1') ).to be_truthy
    end
    it "is equal for LGPL-2.1+" do
      expect( License.new(:name => 'LGPL-2.1+').equals_id?('LGPL-2.1+') ).to be_truthy
    end
    it "is equal for LGPL-2.1+" do
      expect( License.new(:name => 'LGPL-2.1+').equals_id?('LGPL-3.0') ).to be_truthy
    end
    it "is equal for LGPL-2.1+" do
      expect( License.new(:name => 'LGPL-2.1+').equals_id?('LGPL-3.0+') ).to be_truthy
    end

    it "is equal for LGPL-3.0+" do
      expect( License.new(:name => 'LGPL-3.0+').equals_id?('LGPL-2.0') ).to be_falsey
    end
    it "is equal for LGPL-3.0+" do
      expect( License.new(:name => 'LGPL-3.0+').equals_id?('LGPL-2.0+') ).to be_falsey
    end
    it "is equal for LGPL-3.0+" do
      expect( License.new(:name => 'LGPL-3.0+').equals_id?('LGPL-2.1') ).to be_falsey
    end
    it "is equal for LGPL-3.0+" do
      expect( License.new(:name => 'LGPL-3.0+').equals_id?('LGPL-2.0+') ).to be_falsey
    end
    it "is equal for LGPL-3.0+" do
      expect( License.new(:name => 'LGPL-3.0+').equals_id?('LGPL-3.0') ).to be_truthy
    end
    it "is equal for LGPL-3.0+" do
      expect( License.new(:name => 'LGPL-3.0+').equals_id?('LGPL-3.0+') ).to be_truthy
    end


    it "is equal for GPL-1.0+" do
      expect( License.new(:name => 'GPL-1.0+').equals_id?('GPL-1.0') ).to be_truthy
    end
    it "is equal for GPL-1.0+" do
      expect( License.new(:name => 'GPL-1.0+').equals_id?('GPL-1.0+') ).to be_truthy
    end
    it "is equal for GPL-1.0+" do
      expect( License.new(:name => 'GPL-1.0+').equals_id?('GPL-2.0') ).to be_truthy
    end
    it "is equal for GPL-1.0+" do
      expect( License.new(:name => 'GPL-1.0+').equals_id?('GPL-2.0+') ).to be_truthy
    end
    it "is equal for GPL-1.0+" do
      expect( License.new(:name => 'GPL-1.0+').equals_id?('GPL-3.0') ).to be_truthy
    end
    it "is equal for GPL-1.0+" do
      expect( License.new(:name => 'GPL-1.0+').equals_id?('GPL-3.0+') ).to be_truthy
    end


    it "is equal for GPL-2.0+" do
      expect( License.new(:name => 'GPL-2.0+').equals_id?('GPL-1.0') ).to be_falsey
    end
    it "is equal for GPL-2.0+" do
      expect( License.new(:name => 'GPL-2.0+').equals_id?('GPL-1.0+') ).to be_falsey
    end
    it "is equal for GPL-2.0+" do
      expect( License.new(:name => 'GPL-2.0+').equals_id?('GPL-2.0') ).to be_truthy
    end
    it "is equal for GPL-2.0+" do
      expect( License.new(:name => 'GPL-2.0+').equals_id?('GPL-2.0+') ).to be_truthy
    end
    it "is equal for GPL-2.0+" do
      expect( License.new(:name => 'GPL-2.0+').equals_id?('GPL-3.0') ).to be_truthy
    end
    it "is equal for GPL-2.0+" do
      expect( License.new(:name => 'GPL-2.0+').equals_id?('GPL-3.0+') ).to be_truthy
    end


    it "is equal for GPL-3.0+" do
      expect( License.new(:name => 'GPL-3.0+').equals_id?('GPL-1.0') ).to be_falsey
    end
    it "is equal for GPL-3.0+" do
      expect( License.new(:name => 'GPL-3.0+').equals_id?('GPL-1.0+') ).to be_falsey
    end
    it "is equal for GPL-3.0+" do
      expect( License.new(:name => 'GPL-3.0+').equals_id?('GPL-2.0') ).to be_falsey
    end
    it "is equal for GPL-3.0+" do
      expect( License.new(:name => 'GPL-3.0+').equals_id?('GPL-2.0+') ).to be_falsey
    end
    it "is equal for GPL-3.0+" do
      expect( License.new(:name => 'GPL-3.0+').equals_id?('GPL-3.0') ).to be_truthy
    end
    it "is equal for GPL-3.0+" do
      expect( License.new(:name => 'GPL-3.0+').equals_id?('GPL-3.0+') ).to be_truthy
    end

  end

  describe "link" do

    it "should return mit link" do
      license = License.new({:name => "MIT"})
      license.link.should eq("http://spdx.org/licenses/MIT.html")
    end
    it "should return mit link" do
      license = License.new({:name => "mit"})
      license.link.should eq("http://spdx.org/licenses/MIT.html")
    end
    it "should return mit link" do
      license = License.new({:name => "The MIT License"})
      license.link.should eq("http://spdx.org/licenses/MIT.html")
    end
    it "should return mit link" do
      license = License.new({:name => "MIT License"})
      license.link.should eq("http://spdx.org/licenses/MIT.html")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.link.should eq("http://spdx.org/licenses/Apache-2.0.html")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.link.should eq("http://spdx.org/licenses/Apache-2.0.html")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "The Apache Software License, Version 2.0"})
      license.link.should eq("http://spdx.org/licenses/Apache-2.0.html")
    end
    it "should return json link" do
      license = License.new({:name => "the json licensE"})
      license.link.should eq("http://spdx.org/licenses/JSON.html")
    end
    it "should return cddl 1.0 link" do
      license = License.new({:name => "Common Development and Distribution License 1.0"})
      license.link.should eq("http://spdx.org/licenses/CDDL-1.0.html")
    end
    it "should return cddl 1.0 link" do
      license = License.new({:name => "Common Development and Distribution License 1.1"})
      license.name_substitute.should eq("CDDL-1.1")
      license.link.should eq("http://spdx.org/licenses/CDDL-1.1.html")
    end

  end

  describe "name_substitute" do

    it "should return PHP-3.01 name" do
      license = License.new({:name => "xpp license"})
      license.name_substitute.should eq("xpp")
    end


    it "should return PHP-3.01 name" do
      license = License.new({:name => "The PHP License, version 3.01"})
      license.name_substitute.should eq("PHP-3.01")
    end
    it "should return PHP-3.01 name" do
      license = License.new({:name => "The PHP License Version 3.01"})
      license.name_substitute.should eq("PHP-3.01")
    end
    it "should return PHP-3.01 name" do
      license = License.new({:name => "PHP version 3.01"})
      license.name_substitute.should eq("PHP-3.01")
    end
    it "should return PHP-3.01 name" do
      license = License.new({:name => "PHP 3.01"})
      license.name_substitute.should eq("PHP-3.01")
    end
    it "should return PHP-3.01 name" do
      license = License.new({:name => "PHP License v3.01"})
      license.name_substitute.should eq("PHP-3.01")
    end


    it "should return PHP-3.0 name" do
      license = License.new({:name => "The PHP License, version 3.0"})
      license.name_substitute.should eq("PHP-3.0")
    end
    it "should return PHP-3.0 name" do
      license = License.new({:name => "The PHP License Version 3.0"})
      license.name_substitute.should eq("PHP-3.0")
    end
    it "should return PHP-3.0 name" do
      license = License.new({:name => "PHP version 3.0"})
      license.name_substitute.should eq("PHP-3.0")
    end
    it "should return PHP-3.0 name" do
      license = License.new({:name => "PHP v3.0"})
      license.name_substitute.should eq("PHP-3.0")
    end
    it "should return PHP-3.0 name" do
      license = License.new({:name => "PHP License v3.0"})
      license.name_substitute.should eq("PHP-3.0")
    end


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
    it "should return MIT name" do
      license = License.new({:name => "The MIT License (MIT)"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "MIT/X11"})
      license.name_substitute.should eq("MIT")
    end


    it "should return Unlicense name" do
      license = License.new({:name => "Public domain (Unlicense)"})
      license.name_substitute.should eq('Unlicense')
    end
    it "should return Unlicense name" do
      license = License.new({:name => "The Unlicense"})
      license.name_substitute.should eq('Unlicense')
    end
    it "should return Unlicense name" do
      license = License.new({:name => "unlicense.org"})
      license.name_substitute.should eq('Unlicense')
    end
    it "should return Unlicense name" do
      license = License.new({:name => "UNLICENSE"})
      license.name_substitute.should eq('Unlicense')
    end
    it "should return Unlicense name" do
      license = License.new({:name => "Unlicense (Public Domain)"})
      license.name_substitute.should eq('Unlicense')
    end
    it "should return Unlicense name" do
      license = License.new({:name => "https://spdx.org/licenses/Unlicense.html"})
      license.name_substitute.should eq('Unlicense')
    end


    it "check for CDDL and GPL license" do
      license = License.new({:name => "CDDL+GPL"})
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "CDDL + GPL"})
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "CDDL plus GPL"})
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "COMMON DEVELOPMENT AND DISTRIBUTION (CDDL) plus GPL"})
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "COMMON DEVELOPMENT AND DISTRIBUTION plus GPL"})
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "COMMON DEVELOPMENT AND DISTRIBUTION LICENSE (CDDL) plus GPL"})
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "CDDL1", :url => "https://glassfish.java.net/nonav/public/CDDL+GPL.html" })
      license.name_substitute.should eq("CDDL+GPL")
    end
    it "check for CDDL and GPL license" do
      license = License.new({:name => "CDDL1", :url => "https://glassfish.java.net/public/CDDL+GPL.html" })
      license.name_substitute.should eq("CDDL+GPL")
    end


    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL + GPL with CPE"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL  + GPLv2 with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL+GPLv2 with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL + GPL2 with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL + GPL 2.0 License with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL + GPL2 w/ CPE"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL + GPLv2 with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "COMMON DEVELOPMENT AND DISTRIBUTION plus GPL 2.0 with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "COMMON DEVELOPMENT AND DISTRIBUTION plus GPLv2 with classpath exception"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL or GPLv2 with exceptions"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL+GPL_1_1"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "Dual license consisting of the CDDL v1.1 and GPL v2"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL v1.1 and GPL v2"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL v1.1 / GPL v2 dual license"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL/GPLv2+CE"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL + GPL 1.1"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "CDDL+GPL 1.1"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "GPL2", :url => "https://glassfish.java.net/nonav/public/CDDL+GPL_1_1.html"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end
    it "should return CDDL+GPLv2 with classpath exception name" do
      license = License.new({:name => "GPL2", :url => "https://glassfish.java.net/public/CDDL+GPL_1_1.html"})
      license.name_substitute.should eq("CDDL+GPLv2 with classpath exception")
    end


    it "should return BSD-4-Clause-UC name" do
      license = License.new({:name => "BSD 4-clause UC"})
      license.name_substitute.should eq("BSD-4-Clause-UC")
    end
    it "should return BSD-4-Clause-UC name" do
      license = License.new({:name => "BSD-4-Clause (University of California-Specific)"})
      license.name_substitute.should eq("BSD-4-Clause-UC")
    end


    it "should return BSD name" do
      license = License.new({:name => "BSD"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "BSD License"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "BSD style"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "BSD like"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "Berkeley Software Distribution (BSD) License"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "Berkeley Software Distribution License"})
      license.name_substitute.should eq("BSD")
    end



    it "should return BSD 2-Clause name" do
      license = License.new({:name => "The BSD 2 clause"})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "\"BSD 2-clause \"\"Simplified\"\" License\""})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "The BSD 2 clause revised license"})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "BSD 2 clause Simplified License"})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "BSD 2 clause \"Simplified\" License"})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "2 clause BSd"})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "2 clause BSdL"})
      license.name_substitute.should eq("BSD-2-Clause")
    end
    it "should return BSD 2-Clause name" do
      license = License.new({:name => "BSD", :url => 'http://opensource.org/licenses/BSD-2-Clause'})
      license.name_substitute.should eq("BSD-2-Clause")
    end


    it "should return BSD 2-Clause-freebsd name" do
      license = License.new({:name => "BSD 2 clause FreeBSD"})
      license.name_substitute.should eq("BSD-2-Clause-FreeBSD")
    end
    it "should return BSD 2-Clause-netbsd name" do
      license = License.new({:name => "FreeBSD License"})
      license.name_substitute.should eq("BSD-2-Clause-FreeBSD")
    end


    it "should return BSD 2-Clause-netbsd name" do
      license = License.new({:name => "BSD 2-clause NetBSD License"})
      license.name_substitute.should eq("BSD-2-Clause-NetBSD")
    end
    it "should return BSD 2-Clause-netbsd name" do
      license = License.new({:name => "BSD 2 NetBSD"})
      license.name_substitute.should eq("BSD-2-Clause-NetBSD")
    end



    it "should return BSD 3-Clause name" do
      license = License.new({:name => "The BSD 3-clause"})
      license.name_substitute.should eq("BSD-3-Clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "The BSD 3 clause revised license"})
      license.name_substitute.should eq("BSD-3-Clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "new bsd"})
      license.name_substitute.should eq("BSD-3-Clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "revised bsd"})
      license.name_substitute.should eq("BSD-3-Clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "\"BSD 3-clause \"\"New\"\" or \"\"Revised\"\" License\""})
      license.name_substitute.should eq("BSD-3-Clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "new bsd"})
      license.name_substitute.should eq("BSD-3-Clause")
    end
    it "should return BSD 3-Clause name" do
      license = License.new({:name => "revised bsd"})
      license.name_substitute.should eq("BSD-3-Clause")
    end


    it "should return BSD 3-Clause-Clear clear name" do
      license = License.new({:name => "BSD 3-clause Clear License"})
      license.name_substitute.should eq("BSD-3-Clause-Clear")
    end
    it "should return BSD 3-Clause-Clear clear name" do
      license = License.new({:name => "The clear bsd Lizenz"})
      license.name_substitute.should eq("BSD-3-Clause-Clear")
    end


    it "should return BSD-4-Clause name" do
      license = License.new({:name => "old bsd license"})
      license.name_substitute.should eq("BSD-4-Clause")
    end
    it "should return BSD-4-Clause name" do
      license = License.new({:name => "old bsd licence"})
      license.name_substitute.should eq("BSD-4-Clause")
    end
    it "should return BSD-4-Clause name" do
      license = License.new({:name => "original bsd licence"})
      license.name_substitute.should eq("BSD-4-Clause")
    end
    it "should return BSD-4-Clause name" do
      license = License.new({:name => "BSD 4-clause \"Original\" or \"Old\" License"})
      license.name_substitute.should eq("BSD-4-Clause")
    end
    it "should return BSD-4-Clause name" do
      license = License.new({:name => "BSD 4 clause"})
      license.name_substitute.should eq("BSD-4-Clause")
    end



    it "should return MPL-2.0" do
      license = License.new({:name => "Mozilla Public License 2.0"})
      license.name_substitute.should eq("MPL-2.0")
    end
    it "should return MPL-2.0" do
      license = License.new({:name => "Mozilla Public License 2.0 (MPL 2.0)"})
      license.name_substitute.should eq("MPL-2.0")
    end
    it "should return MPL-2.0" do
      license = License.new({:name => "MPLv2.0"})
      license.name_substitute.should eq("MPL-2.0")
    end



    it "should return MPL-1.1" do
      license = License.new({:name => "Mozilla Public License 1.1"})
      license.name_substitute.should eq("MPL-1.1")
    end
    it "should return MPL-1.1" do
      license = License.new({:name => "Mozilla Public License 1.1 (MPL 1.1)"})
      license.name_substitute.should eq("MPL-1.1")
    end
    it "should return MPL-1.1" do
      license = License.new({:name => "MPLv1.1"})
      license.name_substitute.should eq("MPL-1.1")
    end



    it "should return MPL-1.0" do
      license = License.new({:name => "Mozilla Public License 1.0"})
      license.name_substitute.should eq("MPL-1.0")
    end
    it "should return MPL-1.0" do
      license = License.new({:name => "Mozilla Public License 1"})
      license.name_substitute.should eq("MPL-1.0")
    end
    it "should return MPL-1.0" do
      license = License.new({:name => "Mozilla Public License 1.0 (MPL 1.0)"})
      license.name_substitute.should eq("MPL-1.0")
    end
    it "should return MPL-1.0" do
      license = License.new({:name => "MPLv1"})
      license.name_substitute.should eq("MPL-1.0")
    end
    it "should return MPL-1.0" do
      license = License.new({:name => "MPLv1.0"})
      license.name_substitute.should eq("MPL-1.0")
    end


    it "should return Ruby name" do
      license = License.new({:name => "Ruby"})
      license.name_substitute.should eq("Ruby")
    end
    it "should return Ruby name" do
      license = License.new({:name => "Ruby License"})
      license.name_substitute.should eq("Ruby")
    end
    it "should return Ruby name" do
      license = License.new({:name => "The Ruby License"})
      license.name_substitute.should eq("Ruby")
    end


    it "should return GPL name" do
      license = License.new({:name => "GNU General Public License (GPL)"})
      license.name_substitute.should eq("GPL")
    end


    it "should return GPL 1.0+ name" do
      license = License.new({:name => "General Public License, version 1 or greater"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "GPL-1.0+"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "gpl 1+"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "gpl 1.0+"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "GPL v1.0+"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "gplv1+"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "gplv1.0+"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "GPLv1 or later"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "GNU General Public License 1.0 or greater"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "GPL version 1 or later"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "GNU General Public License v1.0 or later"})
      license.name_substitute.should eq("GPL-1.0+")
    end
    it "should return GPL 1.0+ name" do
      license = License.new({:name => "General Public License 1 or later"})
      license.name_substitute.should eq("GPL-1.0+")
    end


    it "should return GPL 1.0 name" do
      license = License.new({:name => "GNU General Public License v1.0 only"})
      license.name_substitute.should eq("GPL-1.0")
    end
    it "should return GPL 1.0 name" do
      license = License.new({:name => "GPL 1"})
      license.name_substitute.should eq("GPL-1.0")
    end
    it "should return GPL 1.0 name" do
      license = License.new({:name => "GNU General public v1"})
      license.name_substitute.should eq("GPL-1.0")
    end
    it "should return GPL 1.0 name" do
      license = License.new({:name => "GNU General public v1.0 only"})
      license.name_substitute.should eq("GPL-1.0")
    end
    it "should return GPL 1.0 name" do
      license = License.new({:name => "General public v1.0 (GPL-1.0)"})
      license.name_substitute.should eq("GPL-1.0")
    end


    it "should return GPL 2.0+ name" do
      license = License.new({:name => "General Public License, version 2 or greater"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GPL-2.0+"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "gpl 2+"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "gpl 2.0+"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GPL v2.0+"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "gplv2+"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "gplv2.0+"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GPLv2 or later"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GNU General Public License 2.0 or greater"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GPL version 2 or later"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GNU General Public License v2.0 or later"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "GNU General Public License (GPL) version 2, or any later version"})
      license.name_substitute.should eq("GPL-2.0+")
    end
    it "should return GPL 2.0+ name" do
      license = License.new({:name => "General Public License 2 or later"})
      license.name_substitute.should eq("GPL-2.0+")
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
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GNU GPLv2"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GNU GPLv2.0"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GNU GPL-2.0"})
      license.name_substitute.should eq("GPL-2.0")
    end


    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "GPL 2.0 w/ cpe"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "GPLv2.0 w/ cpe"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "GPL2 w/ cpe"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "GNU General Public License, version 2, with the Classpath Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "General Public License, version 2, with Classpath Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "General Public License 2 w\ Classpath Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "General Public License 2 w Classpath Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "General Public License 2 + Classpath Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "General Public License 2 + CPE"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "GNU General Public License v2.0 w/Classpath exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "gplv2+ce"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "The GNU General Public License (GPL) Version 2, June 1991 with \"ClassPath\" Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end
    it "should return GPL-2.0-with-classpath-exception name" do
      license = License.new({:name => "The GNU General Public License (GPL) Version 2, June 1991 with classpath Exception"})
      license.name_substitute.should eq("GPL-2.0-with-classpath-exception")
    end




    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU General Public License v3.0 only"})
      license.name_substitute.should eq("GPL-3.0")
    end
    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU General Public License v3.0"})
      license.name_substitute.should eq("GPL-3.0")
    end
    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU General Public License (GPL 3.0)"})
      license.name_substitute.should eq("GPL-3.0")
    end
    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU    General Public  License  (GPL-3.0)"})
      license.name_substitute.should eq("GPL-3.0")
    end
    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU    General Public  License 3.0 (GPL-3.0)"})
      license.name_substitute.should eq("GPL-3.0")
    end
    it "should return GPL 3.0 name" do
      license = License.new({:name => "General Public  License 3.0"})
      license.name_substitute.should eq("GPL-3.0")
    end
    it "should return GPL 3.0 name" do
      license = License.new({:name => "GNU General Public License", :url => 'http://www.gnu.org/licenses/gpl.txt'})
      license.name_substitute.should eq("GPL-3.0")
    end


    it "should return GPL 3.0+ name" do
      license = License.new({:name => "General Public License, version 3 or greater"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GPL-3.0+"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "gpl 3+"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "gpl 3.0+"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "gplv3+"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "gplv3.0+"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GPLv3 or later"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GNU General Public License 3.0 or greater"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GPL version 3 or later"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GNU General Public License v3.0 or later"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "General Public License 3 or later"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GNU General Public License v3 or later (GPLv3+)"})
      license.name_substitute.should eq("GPL-3.0+")
    end
    it "should return GPL 3.0+ name" do
      license = License.new({:name => "GPLv3 GNU General Public License v3 or later (GPLv3+)"})
      license.name_substitute.should eq("GPL-3.0+")
    end


    it "should return LGPL 2.0 name" do
      license = License.new({:name => "GNU Lesser General Public License v2.0 only"})
      license.name_substitute.should eq("LGPL-2.0")
    end
    it "should return LGPL 2.0 name" do
      license = License.new({:name => "lgplv2.0"})
      license.name_substitute.should eq("LGPL-2.0")
    end
    it "should return LGPL 2.0 name" do
      license = License.new({:name => "lgplv2"})
      license.name_substitute.should eq("LGPL-2.0")
    end
    it "should return LGPL 2.0 name" do
      license = License.new({:name => "lgpl  2.0"})
      license.name_substitute.should eq("LGPL-2.0")
    end
    it "should return LGPL 2.0 name" do
      license = License.new({:name => "GNU Lesser General Public License v2.0 only"})
      license.name_substitute.should eq("LGPL-2.0")
    end
    it "should return LGPL 2.0 name" do
      license = License.new({:name => "GNU Lesser General Public License (LGPl) v2.0 only"})
      license.name_substitute.should eq("LGPL-2.0")
    end
    it "should return LGPL 2.0 name" do
      license = License.new({:name => "GNU Lesser General Public License (LGPl) v2.0"})
      license.name_substitute.should eq("LGPL-2.0")
    end


    # it "should return LGPL 2.0 name" do
    #   license = License.new({:name => "GNU Library General Public License v2 or later"})
    #   license.name_substitute.should eq("LGPL-2.0+")
    # end


    it "should return LGPL 2.1 name" do
      license = License.new({:name => "GNU Lesser General Public License v2.1 only"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "lgpl"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "lgplv2.1"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "lgpl  2.1"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "GNU Lesser General Public License v2.1 only"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "LGPL-2.1"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "GNU Lesser General Public License Version 2.1, February 1999"})
      license.name_substitute.should eq("LGPL-2.1")
    end
    it "should return LGPL 2.1 name" do
      license = License.new({:name => "GNU LIBRARY GENERAL PUBLIC LICENSE, Version 2.1, February 1999"})
      license.name_substitute.should eq("LGPL-2.1")
    end


    it "should return LGPL 3.0 name" do
      license = License.new({:name => "GNU Lesser General Public License v3.0 only"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "GNU General Lesser Public License (LGPL) version 3.0"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "GNU Lesser General Public License"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "Gnu Lesser Public License"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "lgplv3"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "lesser general public license"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "GNU lesser general public license v3"})
      license.name_substitute.should eq("LGPL-3.0")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "Lesser General Public License (LGPL v3)"})
      license.name_substitute.should eq("LGPL-3.0")
    end



    it "should return LGPL 3.0+ name" do
      license = License.new({:name => "Lesser General Public License, version 3 or greater"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL 3.0+ name" do
      license = License.new({:name => "LGPL-3.0+"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "lgpl 3+"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "lgpl 3.0+"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "lgplv3+"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "lgplv3.0+"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "LGPLv3 or later"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL 3.0 name" do
      license = License.new({:name => "GNU Library General Public License 3.0 or greater"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "LGPL version 3 or later"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "GNU Lesser General Public License v3.0 or later"})
      license.name_substitute.should eq("LGPL-3.0+")
    end
    it "should return LGPL+3.0+ name" do
      license = License.new({:name => "Lesser General Public License 3 or later"})
      license.name_substitute.should eq("LGPL-3.0+")
    end


    it "should return LGPL 2.0+ name" do
      license = License.new({:name => "LGPL-2.0+"})
      license.name_substitute.should eq("LGPL-2.0+")
    end
    it "should return LGPL 2.0+ name" do
      license = License.new({:name => "GNU Library General Public License v2 or later"})
      license.name_substitute.should eq("LGPL-2.0+")
    end


    it "should return LGPL 2.1+ name" do
      license = License.new({:name => "GNU Library General Public License 2.1 or greater"})
      license.name_substitute.should eq("LGPL-2.1+")
    end
    it "should return LGPL 2.1+ name" do
      license = License.new({:name => "LGPL-2.1+"})
      license.name_substitute.should eq("LGPL-2.1+")
    end


    it "should return AGPL 1.0 name" do
      license = License.new({:name => "GNU AFFERO GENERAL PUBLIC LICENSE Version 1"})
      license.name_substitute.should eq("AGPL-1.0")
    end
    it "should return AGPL 1.0 name" do
      license = License.new({:name => "AFFERO GENERAL PUBLIC LICENSE Version v1.0"})
      license.name_substitute.should eq("AGPL-1.0")
    end
    it "should return AGPL 1.0 name" do
      license = License.new({:name => "AFFERO GENERAL PUBLIC LICENSE (AGPL 1)"})
      license.name_substitute.should eq("AGPL-1.0")
    end
    it "should return AGPL 1.0 name" do
      license = License.new({:name => "AGPL 1.0"})
      license.name_substitute.should eq("AGPL-1.0")
    end
    it "should return AGPL 1.0 name" do
      license = License.new({:name => "AGPLv1.0"})
      license.name_substitute.should eq("AGPL-1.0")
    end
    it "should return AGPL 1.0 name" do
      license = License.new({:name => "AGPLv1"})
      license.name_substitute.should eq("AGPL-1.0")
    end


    it "should return AGPL 3.0 name" do
      license = License.new({:name => "GNU AFFERO GENERAL PUBLIC LICENSE Version 3"})
      license.name_substitute.should eq("AGPL-3.0")
    end
    it "should return AGPL 3.0 name" do
      license = License.new({:name => "AFFERO GENERAL PUBLIC LICENSE Version v3.0"})
      license.name_substitute.should eq("AGPL-3.0")
    end
    it "should return AGPL 3.0 name" do
      license = License.new({:name => "AFFERO GENERAL PUBLIC LICENSE (AGPL 3.0)"})
      license.name_substitute.should eq("AGPL-3.0")
    end
    it "should return AGPL 3.0 name" do
      license = License.new({:name => "AGPL 3.0"})
      license.name_substitute.should eq("AGPL-3.0")
    end
    it "should return AGPL 3.0 name" do
      license = License.new({:name => "AGPLv3.0"})
      license.name_substitute.should eq("AGPL-3.0")
    end
    it "should return AGPL 3.0 name" do
      license = License.new({:name => "AGPLv3"})
      license.name_substitute.should eq("AGPL-3.0")
    end


    it "should return Apache License version 1 name" do
      license = License.new({:name => "The Apache Software License\, Version 1\.0"})
      license.name_substitute.should eq("Apache-1.0")
    end
    it "should return Apache License version 1 name" do
      license = License.new({:name => "ASL1"})
      license.name_substitute.should eq("Apache-1.0")
    end
    it "should return Apache License version 1 name" do
      license = License.new({:name => "ASLv1"})
      license.name_substitute.should eq("Apache-1.0")
    end
    it "should return Apache License version 1 name" do
      license = License.new({:name => "Apache v1 Lizenz"})
      license.name_substitute.should eq("Apache-1.0")
    end


    it "should return Apache License version 1.1 name" do
      license = License.new({:name => "The Apache Software License\, Version 1\.1"})
      license.name_substitute.should eq("Apache-1.1")
    end
    it "should return Apache License version 1.1 name" do
      license = License.new({:name => "ASL-v1.1"})
      license.name_substitute.should eq("Apache-1.1")
    end
    it "should return Apache License version 1.1 name" do
      license = License.new({:name => "Apache v1.1 Lizenz"})
      license.name_substitute.should eq("Apache-1.1")
    end
    it "should return Apache License version 1.1 name" do
      license = License.new({:name => "Apache public v1.1 Lizenz"})
      license.name_substitute.should eq("Apache-1.1")
    end
    it "should return Apache License version 1.1 name" do
      license = License.new({:name => "ASLv1.1"})
      license.name_substitute.should eq("Apache-1.1")
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
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache2"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache 2.0 License (http://www.apache.org/licenses/LICENSE-2.0.html)"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License\r\n                       Version 2.0, January 2004"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Licensed under the Apache License, Version 2.0 (the \"License\");\n   you may not use"})
      license.name_substitute.should eq("Apache-2.0")
    end
    # it "should return Apache License version 2 name" do
    #   license = License.new({:name => "Copyright 2014 Ales Komarek & Michael Kuty\n\nLicensed under the Apache License, Version 2.0 (the \"License\");\nyou may not use this file except in compliance with the License.\nYou may obtain a copy of the License at\n\n   http://www.apache.org/licenses/LICENSE-2.0\n\nUnless required by applicable law or agreed to in writing, software\ndistributed under the License is distributed on an \"AS IS\" BASIS,\nWITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\nSee the License for the specific language governing permissions and\nlimitations under the License."})
    #   license.name_substitute.should eq("Apache-2.0")
    # end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache, Version 2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end



    it "should return Apache License name" do
      license = License.new({:name => "Apache License"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache 2 License"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache 2.0 License"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache v2.0 License"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache v2 License"})
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
    it "should return Apache License name" do
      license = License.new({:name => "ASL 2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "ASL 2"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "ASLv2"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache v2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache v2"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Public License 2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Public Licence v2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Public LicENce v2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Public LicenSe v2.0"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache License ASL Version 2"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Software License Version 2"})
      license.name_substitute.should eq("Apache-2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Software Licenses"})
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
    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse Public License (EPL) 1.0"})
      license.name_substitute.should eq("EPL-1.0")
    end


    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution LiCense"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution LiCense v1"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "EDL v1"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "EDLv1"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution License v. 1.0"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution License (New BSD License)"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution License - v 1.0"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution License - v1.0"})
      license.name_substitute.should eq("EDL-1.0")
    end
    it "should return eclipse distributed license name" do
      license = License.new({:name => "Eclipse Distribution License v1.0"})
      license.name_substitute.should eq("EDL-1.0")
    end


    it "should return ClArtistic license name" do
      license = License.new({:name => "clArtistic"})
      license.name_substitute.should eq("ClArtistic")
    end
    it "should return ClArtistic license name" do
      license = License.new({:name => "the Clarified Artistic License"})
      license.name_substitute.should eq("ClArtistic")
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


    it "should return Artistic-1.0-Perl license name" do
      license = License.new({:name => "Artistic 1.0 Perl"})
      license.name_substitute.should eq("Artistic-1.0-Perl")
    end
    it "should return Artistic-1.0-Perl license name" do
      license = License.new({:name => "Artistic v1.0 License (Perl)"})
      license.name_substitute.should eq("Artistic-1.0-Perl")
    end
    it "should return Artistic-1.0-Perl license name" do
      license = License.new({:name => "Artistic-1.0-Perl"})
      license.name_substitute.should eq("Artistic-1.0-Perl")
    end


    it "should return Artistic-1.0-cl8 license name" do
      license = License.new({:name => "Artistic 1.0 cl8"})
      license.name_substitute.should eq("Artistic-1.0-cl8")
    end
    it "should return Artistic-1.0-cl8 license name" do
      license = License.new({:name => "Artistic v1.0 License w/clause 8"})
      license.name_substitute.should eq("Artistic-1.0-cl8")
    end


    it "should return Artistic-2.0 license name" do
      license = License.new({:name => "Artistic 2.0"})
      license.name_substitute.should eq("Artistic-2.0")
    end
    it "should return Artistic-2.0 license name" do
      license = License.new({:name => "Artistic-2.0 Licence"})
      license.name_substitute.should eq("Artistic-2.0")
    end
    it "should return Artistic-2.0 license name" do
      license = License.new({:name => "Perl Artistic v2.0 Licence"})
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
    it "should return JSON License name" do
      license = License.new({:name => "The JSON License"})
      license.name_substitute.should eq('JSON')
    end


    it "check for CDDL 1.0 license" do
      license = License.new({:name => "Common Development and Distribution License 1.0"})
      license.name_substitute.should eq("CDDL-1.0")
    end
    it "check for CDDL 1.0 license" do
      license = License.new({:name => "Common Development and Distribution (CDDL) v1"})
      license.name_substitute.should eq("CDDL-1.0")
    end
    it "check for CDDL 1.0 license" do
      license = License.new({:name => "Common Development and Distribution (CDDL) 1"})
      license.name_substitute.should eq("CDDL-1.0")
    end
    it "check for CDDL 1.0 license" do
      license = License.new({:name => "Common Development and Distribution (CDDL 1)"})
      license.name_substitute.should eq("CDDL-1.0")
    end
    it "check for CDDL 1.0 license" do
      license = License.new({:name => "CDDL 1"})
      license.name_substitute.should eq("CDDL-1.0")
    end
    it "check for CDDL 1.0 license" do
      license = License.new({:name => "CDDL-v1"})
      license.name_substitute.should eq("CDDL-1.0")
    end


    it "check for CDDL 1.1 license" do
      license = License.new({:name => "Common Development and Distribution License 1.1"})
      license.name_substitute.should eq("CDDL-1.1")
    end
    it "check for CDDL 1.1 license" do
      license = License.new({:name => "Common Development and Distribution (CDDL) v1.1"})
      license.name_substitute.should eq("CDDL-1.1")
    end
    it "check for CDDL 1.1 license" do
      license = License.new({:name => "Common Development and Distribution (CDDL) 1.1"})
      license.name_substitute.should eq("CDDL-1.1")
    end
    it "check for CDDL 1.1 license" do
      license = License.new({:name => "Common Development and Distribution (CDDL 1.1)"})
      license.name_substitute.should eq("CDDL-1.1")
    end
    it "check for CDDL 1.1 license" do
      license = License.new({:name => "CDDL v1.1"})
      license.name_substitute.should eq("CDDL-1.1")
    end
    it "check for CDDL 1.1 license" do
      license = License.new({:name => "CDDL-v1.1"})
      license.name_substitute.should eq("CDDL-1.1")
    end


    it "check for CPL 1 license" do
      license = License.new({:name => "CPL1"})
      license.name_substitute.should eq("CPL-1.0")
    end
    it "check for CPL 1 license" do
      license = License.new({:name => "Common public licence v 1"})
      license.name_substitute.should eq("CPL-1.0")
    end
    it "check for CPL 1 license" do
      license = License.new({:name => "Common public licence v1.0"})
      license.name_substitute.should eq("CPL-1.0")
    end


    it "check for CC-BY-SA-2.5 license" do
      license = License.new({:name => "CC-BY-SA-2.5"})
      license.name_substitute.should eq("CC-BY-SA-2.5")
    end
    it "check for CC-BY-SA-2.5 license" do
      license = License.new({:name => "Creative Commons 2.5 BY-SA"})
      license.name_substitute.should eq("CC-BY-SA-2.5")
    end
    it "check for CC-BY-SA-2.5 license" do
      license = License.new({:name => "cc 2.5 BY-SA"})
      license.name_substitute.should eq("CC-BY-SA-2.5")
    end
    it "check for CC-BY-SA-2.5 license" do
      license = License.new({:name => "Creative Commons Attribution share alike 2.5"})
      license.name_substitute.should eq("CC-BY-SA-2.5")
    end

    it "check for CC-BY-SA-3.0 license" do
      license = License.new({:name => "CC-BY-SA-3.0"})
      license.name_substitute.should eq("CC-BY-SA-3.0")
    end
    it "check for CC-BY-SA-3.0 license" do
      license = License.new({:name => "Creative Commons 3.0 BY-SA"})
      license.name_substitute.should eq("CC-BY-SA-3.0")
    end
    it "check for CC-BY-SA-3.0 license" do
      license = License.new({:name => "cc 3.0 BY-SA"})
      license.name_substitute.should eq("CC-BY-SA-3.0")
    end
    it "check for CC-BY-SA-3.0 license" do
      license = License.new({:name => "Creative Commons Attribution share alike 3.0"})
      license.name_substitute.should eq("CC-BY-SA-3.0")
    end

    it "check for CC-BY-SA-4.0 license" do
      license = License.new({:name => "CC-BY-SA-4.0"})
      license.name_substitute.should eq("CC-BY-SA-4.0")
    end
    it "check for CC-BY-SA-4.0 license" do
      license = License.new({:name => "Creative Commons 4.0 BY-SA"})
      license.name_substitute.should eq("CC-BY-SA-4.0")
    end
    it "check for CC-BY-SA-4.0 license" do
      license = License.new({:name => "cc 4.0 BY-SA"})
      license.name_substitute.should eq("CC-BY-SA-4.0")
    end
    it "check for CC-BY-SA-4.0 license" do
      license = License.new({:name => "Creative Commons Attribution share alike 4.0"})
      license.name_substitute.should eq("CC-BY-SA-4.0")
    end

    it "check for CC0-1.0 license" do
      license = License.new({:name => "CC0-1"})
      license.name_substitute.should eq("CC0-1.0")
    end
    it "check for CC0-1.0 license" do
      license = License.new({:name => "CC0-1.0"})
      license.name_substitute.should eq("CC0-1.0")
    end
    it "check for CC0-1.0 license" do
      license = License.new({:name => "CC0 1.0"})
      license.name_substitute.should eq("CC0-1.0")
    end
    it "check for CC0-1.0 license" do
      license = License.new({:name => "CC0 1.0 Universal"})
      license.name_substitute.should eq("CC0-1.0")
    end
    it "check for CC0-1.0 license" do
      license = License.new({:name => "CC0 1 Universal"})
      license.name_substitute.should eq("CC0-1.0")
    end
    it "check for CC0-1.0 license" do
      license = License.new({:name => "cc0-1 universal"})
      license.name_substitute.should eq("CC0-1.0")
    end

    it "check for SAP DEVELOPER LICENSE AGREEMENT license" do
      license = License.new({:name => "SAP DEVELOPER LICENSE AGREEMENT"})
      license.name_substitute.should eq("SAP DEVELOPER LICENSE AGREEMENT")
    end

    it "check Zlib" do
      license = License.new({:name => "ZLIB license"})
      license.name_substitute.should eq("Zlib")
      spdx = SpdxLicense.new({:fullname => 'zlib License', :identifier => 'Zlib'})
      spdx.save
      license.name_substitute.should eq("Zlib")
    end

  end

end

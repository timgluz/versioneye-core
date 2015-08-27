require 'spec_helper'

describe UploadUpdater do

  describe 'update' do

    it 'returns the updated project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.sum_reset!
      project.save

      project = described_class.new.update project
      project.should_not be_nil
      project.dependencies.count.should == 3

      expect( project.dep_number ).to eq(3)
      expect( project.out_number ).to eq(2)
      expect( project.unknown_number ).to eq(0)
      expect( project.licenses_red ).to eq(0)
      expect( project.licenses_unknown ).to eq(3)

      expect( project.dep_number_sum ).to eq(3)
      expect( project.out_number_sum ).to eq(2)
      expect( project.unknown_number_sum ).to eq(0)
      expect( project.licenses_red_sum ).to eq(0)
      expect( project.licenses_unknown_sum ).to eq(3)

      ProjectService.outdated_dependencies( project ).count.should == 2
    end

    it 'returns the updated project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.sum_reset!
      project.source = Project::A_SOURCE_UPLOAD
      project.save

      dep = Projectdependency.first
      product = Product.first
      product.version = dep.version_requested
      LicenseFactory.create_new product, 'GPL'
      expect( License.count ).to eq(1)

      LicenseWhitelistService.create user, 'SuperList'
      LicenseWhitelistService.add user, 'SuperList', 'MIT'
      lwl = LicenseWhitelistService.fetch_by user, 'SuperList'
      project.license_whitelist_id = lwl.ids
      project.save

      project = ProjectUpdateService.update project
      project.should_not be_nil
      project.dependencies.count.should == 3

      expect( project.dep_number ).to eq(3)
      expect( project.out_number ).to eq(2)
      expect( project.unknown_number ).to eq(0)
      expect( project.licenses_red ).to eq(1)
      expect( project.licenses_unknown ).to eq(2)

      expect( project.dep_number_sum ).to eq(3)
      expect( project.out_number_sum ).to eq(2)
      expect( project.unknown_number_sum ).to eq(0)
      expect( project.licenses_red_sum ).to eq(1)
      expect( project.licenses_unknown_sum ).to eq(2)
    end

  end

end

require 'spec_helper'
require 'vcr'
require 'webmock'

describe SyncWorker do

  describe 'work' do

    it 'syncs all products' do
      env = Settings.instance.environment
      GlobalSetting.set env, 'api_key', 'b71fb2'

      product_2 = ProductFactory.create_for_gemfile 'vcr', '0.0.0'
      expect( product_2.save ).to be_truthy
      expect( product_2.versions.count ).to eq(1)

      VCR.use_cassette('sync_worker_all_products', allow_playback_repeats: true) do
        worker1 = Thread.new{ SyncWorker.new.work }

        SyncProducer.new('all_products')
        p "sleep 7"
        sleep 7
        p "wake up & exit worker."
        worker1.exit
      end
      product_2.reload
      expect( product_2.versions.count ).to eq(5)
    end

    it 'syncs a project' do
      env = Settings.instance.environment
      GlobalSetting.set env, 'api_key', '3958165e66dag2'

      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      expect(project.save).to be_truthy

      pdep1 = Projectdependency.new({:language => 'Ruby', :name => 'phcnotifi', :project_id => project.ids})
      expect( pdep1.save ).to be_truthy
      pdep2 = Projectdependency.new({:language => 'Ruby', :name => 'ronn', :project_id => project.ids})
      expect( pdep2.save ).to be_truthy

      expect( project.projectdependencies.count ).to eq(2)
      expect( Product.count ).to eq(0)

      VCR.use_cassette('sync_worker_project', allow_playback_repeats: true) do
        worker1 = Thread.new{ SyncWorker.new.work }

        SyncProducer.new("project::#{project.ids}")

        p "sleep 7"
        sleep 7
        p "wake up & exit worker."
        worker1.exit
      end

      expect( Product.count ).to eq(2)
    end

  end

end

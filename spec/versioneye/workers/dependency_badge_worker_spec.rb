require 'spec_helper'

describe DependencyBadgeWorker do


  describe 'import_from_bitbucket_async' do

    it 'imports from bitbucket async' do

      rails = Product.new({:prod_type => Project::A_TYPE_RUBYGEMS,
        :language => Product::A_LANGUAGE_RUBY, :prod_key => 'rails',
        :name => 'rails', :version => "4.0.0"})
      rails.save

      product = Product.new({:prod_type => Project::A_TYPE_RUBYGEMS,
        :language => Product::A_LANGUAGE_RUBY, :prod_key => 'activerecord',
        :name => 'activerecord', :version => "4.0.0"})
      product.add_version('4.0.0')
      product.add_version('3.0.0')
      product.save

      dependency = Dependency.new({:prod_type => rails.prod_type,
        :language => rails.language, :prod_key => rails.prod_key,
        :prod_version => rails.version})
      dependency.dep_prod_key = product.prod_key
      dependency.scope = Dependency::A_SCOPE_RUNTIME
      dependency.version = "3.0.0"
      dependency.save

      language = rails.language
      prod_key = rails.prod_key
      version  = rails.version

      key = "#{language}:::#{prod_key}:::#{version}"
      DependencyService.cache.delete(key)
      Badge.count.should eq(0)

      worker = Thread.new{ described_class.new.work }
      DependencyService.cache.get(key).should be_nil
      DependencyBadgeProducer.new("#{language}:::#{prod_key}:::#{version}")
      sleep 3
      worker.exit

      Badge.count.should eq(1)
      badge = Badge.first
      badge.status.should eq('out_of_date')
      BadgeService.cache.get(key).should_not be_nil
    end

  end


end

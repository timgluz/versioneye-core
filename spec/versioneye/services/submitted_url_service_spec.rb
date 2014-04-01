require 'spec_helper'

describe SubmittedUrlService do

  describe 'update_integration_status' do

    before(:each) do
      @submitted_url_1          = SubmittedUrlFactory.create_new(user_email: "t1@test.com")
      @resource_without_product = ProductResourceFactory.create_new({:submitted_url => @submitted_url_1})

      @user                  = UserFactory.create_new(2)
      @submitted_url_2       = SubmittedUrlFactory.create_new(user_id: @user._id.to_s)
      @submitted_url_2.declined = false
      @submitted_url_2.integrated = false
      @submitted_url_2.save
      @product               = ProductFactory.create_new(:maven)
      @resource_with_product = ProductResourceFactory.create_new({
                                  :submitted_url => @submitted_url_2,
                                  :prod_key => @product.prod_key,
                                  :language => @product.language})
    end

    it 'returns false because there is no product_resource attached.' do
      ActionMailer::Base.deliveries.clear
      submitted_url = SubmittedUrlFactory.create_new(user_email: "t1@test.com")
      SubmittedUrlService.update_integration_status( submitted_url ).should be_false
      ActionMailer::Base.deliveries.size.should == 0
    end

    it 'returns false because the product_resource doesnt has a prod_key. Its not attached to a product yet.' do
      ActionMailer::Base.deliveries.clear
      SubmittedUrlService.update_integration_status(@submitted_url_1).should be_false
      ActionMailer::Base.deliveries.size.should == 0
    end

    it 'returns true when updating is successful' do
      ActionMailer::Base.deliveries.clear
      @submitted_url_2.integrated.should be_false
      SubmittedUrlService.update_integration_status(@submitted_url_2).should be_true
      @submitted_url_2.integrated.should be_true
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe 'update_integration_statuses' do

    before(:each) do
      @submitted_url_0          = SubmittedUrlFactory.create_new(user_email: "t0@test.com")
      @submitted_url_1          = SubmittedUrlFactory.create_new(user_email: "t1@test.com")
      @resource_without_product = ProductResourceFactory.create_new({:submitted_url => @submitted_url_1})

      @user                  = UserFactory.create_new(2)
      @submitted_url_2       = SubmittedUrlFactory.create_new(user_id: @user._id.to_s)
      @submitted_url_2.declined = false
      @submitted_url_2.integrated = false
      @submitted_url_2.save
      @product               = ProductFactory.create_new(:maven)
      @resource_with_product = ProductResourceFactory.create_new({
                                  :submitted_url => @submitted_url_2,
                                  :prod_key => @product.prod_key,
                                  :language => @product.language})
    end

    it 'sends out 1 email because 1 submitted url was integrated' do
      ActionMailer::Base.deliveries.clear
      SubmittedUrlService.update_integration_statuses()
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end

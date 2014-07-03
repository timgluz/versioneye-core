require 'spec_helper'

describe UserEmail do


  describe 'verified?' do

    it 'returns false' do
      ue = UserEmail.new({:email => 'test@det.de'})
      ue.create_verification
      ue.verified?().should be_falsey
    end

    it 'returns true' do
      ue = UserEmail.new({:email => 'test@det.de'})
      ue.verified?().should be_truthy
    end

  end


  describe 'find_by_email' do

    it 'finds the object' do
      ue = UserEmail.new({:email => 'test@det.de'})
      ue.save
      ue = UserEmail.find_by_email 'test@det.de'
      ue.should_not be_nil
    end

    it 'finds the object' do
      ue = UserEmail.find_by_email 'test@det.de'
      ue.should be_nil
    end

  end


  describe 'create_verification' do

    it 'creates an verification' do
      ue = UserEmail.new({:email => 'test@det.de'})
      ue.verification.should be_nil
      ue.create_verification
      ue.verification.should_not be_nil
    end

  end

  describe 'activate' do

    it 'deos not activate because input is nil' do
      ue = UserEmail.new({:email => 'test@det.de'})
      UserEmail.activate!(nil).should be_falsey
    end
    it 'deos not activate because input is empty' do
      ue = UserEmail.new({:email => 'test@det.de'})
      UserEmail.activate!('').should be_falsey
    end
    it 'deos not activate because there is no verification string in db' do
      ue = UserEmail.new({:email => 'test@det.de'})
      UserEmail.activate!('asgasgasa').should be_falsey
    end
    it 'activates' do
      ue = UserEmail.new({:email => 'test@det.de'})
      ue.create_verification
      ue.save.should be_truthy
      ue.verification.should_not be_nil
      UserEmail.activate!( ue.verification ).should be_truthy
      ue.reload
      ue.verification.should be_nil
    end

  end


end

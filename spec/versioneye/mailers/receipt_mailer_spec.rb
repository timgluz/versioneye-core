require 'spec_helper'

describe ReceiptMailer do

  describe 'receipt_email' do

    it 'should contain the receipt pdf' do

      user = UserFactory.create_new
      receipt = ReceiptFactory.create_new 1
      receipt.user = user

      pdf = File.read("./spec/fixtures/files/invoice.pdf")

      email = described_class.receipt_email( receipt, pdf )

      user = receipt.user

      email.to.should eq( [receipt.email] )
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "This is a receipt for your monthly subscription at VersionEye" )
      email.encoded.should include( "Handelsregister" )

      email.attachments.count.should == 1

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end

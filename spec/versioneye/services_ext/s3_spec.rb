require 'spec_helper'


describe S3 do

  describe 'infographic_url_for' do
    it 'returns the url' do
      region = 'eu-west-1'

      Aws.config[:credentials] = creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

      filename = 'actionmailer:3~2~7:runtime.png'
      url = S3.infographic_url_for filename
      expect( url.to_s ).to_not be_empty
      expect( url.to_s ).to eq("https://s3-eu-west-1.amazonaws.com/veye_test_infographics/actionmailer%3A3~2~7%3Aruntime.png")
    end
  end

  # describe 'upload_fileupload - url_for - delete' do
  #   it 'stores the file, gets the url and deletes the file' do
  #     region = 'eu-west-1'

  #     aws_id  = Settings.instance.aws_access_key_id
  #     aws_key = Settings.instance.aws_secret_access_key
  #     creds   = Aws::Credentials.new( aws_id, aws_key )
  #     Aws.config[:credentials] = creds

  #     gemfile = "spec/fixtures/files/Gemfile"
  #     file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
  #     file = {'datafile' => file_attachment}

  #     filename = S3.upload_fileupload file
  #     expect( filename ).to_not be_nil
  #     expect( filename.match(/_Gemfile\z/) ).to_not be_nil

      # s3 = Aws::S3::Resource.new(:region => 'eu-west-1')
      # bucket = s3.bucket( Settings.instance.s3_projects_bucket )
      # found = false
      # bucket.objects.each do |obj|
      #   found = true if obj.key.eql?(filename)
      # end
      # expect (found ).to be_truthy

      # url = S3.url_for filename
      # expect( url ).to_not be_nil
      # expect( url.match(region)   ).to_not be_nil
      # expect( url.match(filename) ).to_not be_nil

      # resp = S3.delete filename
      # s3 = Aws::S3::Resource.new(:region => 'eu-west-1')
      # bucket = s3.bucket( Settings.instance.s3_projects_bucket )
      # found = false
      # bucket.objects.each do |obj|
      #   found = true if obj.key.eql?(filename)
      # end
      # expect( found ).to be_falsey
  #   end
  # end

end

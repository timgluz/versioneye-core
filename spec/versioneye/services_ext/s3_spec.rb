require 'spec_helper'


describe S3 do

  describe 'infographic_url_for' do
    it 'returns the url' do
      region = 'eu-west-1'

      Aws.config[:credentials] = creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

      filename = 'actionmailer:3~2~7:runtime.png'
      url = S3.infographic_url_for filename
      url.to_s.should_not be_empty
      url.to_s.should eq("https://s3-eu-west-1.amazonaws.com/veye_test_infographics/actionmailer%3A3~2~7%3Aruntime.png")
    end
  end

  describe 'upload_fileupload - url_for - delete' do
    it 'stores the file, gets the url and deletes the file' do
      region = 'eu-west-1'

      creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
      Aws.config[:credentials] = creds

      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      filename = S3.upload_fileupload file
      filename.should_not be_nil
      filename.match(/_Gemfile\z/).should_not be_nil

      s3 = Aws::S3::Resource.new(:region => 'eu-west-1')
      bucket = s3.bucket( Settings.instance.s3_projects_bucket )
      found = false
      bucket.objects.each do |obj|
        found = true if obj.key.eql?(filename)
      end
      found.should be_truthy

      url = S3.url_for filename
      url.should_not be_nil
      url.match(region).should_not be_nil
      url.match(filename).should_not be_nil

      resp = S3.delete filename
      s3 = Aws::S3::Resource.new(:region => 'eu-west-1')
      bucket = s3.bucket( Settings.instance.s3_projects_bucket )
      found = false
      bucket.objects.each do |obj|
        found = true if obj.key.eql?(filename)
      end
      found.should be_falsey
    end
  end

end

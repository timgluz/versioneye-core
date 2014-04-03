require 'spec_helper'


describe S3 do

  describe 'upload_fileupload - url_for - delete' do
    it 'stores the file, gets the url and deletes the file' do
      AWS.config(:s3_endpoint => 'localhost', :s3_port => 4567, :use_ssl => false )

      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      filename = S3.upload_fileupload file
      filename.should_not be_nil
      p "S3 filename: #{filename}"

      url = S3.url_for filename
      url.should_not be_nil
      p "S3 url: #{url}"

      resp = S3.delete filename
    end
  end

end

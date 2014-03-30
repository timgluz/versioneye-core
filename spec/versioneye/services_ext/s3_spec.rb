require 'spec_helper'


describe S3 do

  describe 'upload_fileupload' do
    it 'stores the file' do
      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      filename = S3.upload_fileupload file
      filename.should_not be_nil
    end
  end

end

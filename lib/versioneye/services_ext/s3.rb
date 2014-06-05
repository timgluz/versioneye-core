require 'aws-sdk'

class S3 < Versioneye::Service


  def self.set_aws_crendentials
    AWS.config(
      :s3_endpoint => Settings.instance.aws_s3_endpoint,
      :s3_port => Settings.instance.aws_s3_port,
      :use_ssl => Settings.instance.aws_use_ssl,
      :access_key_id => Settings.instance.aws_access_key_id,
      :secret_access_key => Settings.instance.aws_secret_access_key )
  end


  def self.url_for filename
    return nil if filename.to_s.empty?
    encoded_name = URI.encode( filename )
    url = AWS.s3.buckets[Settings.instance.s3_projects_bucket].objects[encoded_name].url_for( :read, :secure => true )
    url.to_s
  rescue => e
    log.error e.message
    log.error "AWS.config: #{AWS.config.s3_endpoint} - #{AWS.config.s3_port} - #{AWS.config.use_ssl} - #{AWS.config.access_key_id} -  #{AWS.config.secret_access_key}"
    log.error e.backtrace.join '\n'
  end


  def self.infographic_url_for filename
    return nil if filename.to_s.empty?
    encoded_name = URI.encode( filename )
    url = AWS.s3.buckets[Settings.instance.s3_infographics_bucket].objects[encoded_name].url_for( :read, :secure => true )
    url.to_s
  rescue => e
    log.error e.message
    log.error e.backtrace.join '\n'
  end


  def self.delete filename
    return nil if filename.nil? || filename.empty?
    AWS.s3.buckets[Settings.instance.s3_projects_bucket].objects[filename].delete
  rescue => e
    log.error e.message
    log.error e.backtrace.join '\n'
  end


  def self.upload_fileupload file_up
    orig_filename = file_up['datafile'].original_filename
    fname         = self.sanitize_filename(orig_filename)
    random        = Project.create_random_value
    filename      = "#{random}_#{fname}"
    self.store_in_project_bucket filename, file_up['datafile'].read
    filename
  rescue => e
    log.error "Exception in S3.upload_fileupload(file_up) #{e.message}"
    log.error e.backtrace.join '\n'
    nil
  end


  def self.store_in_project_bucket filename, bin
    self.store Settings.instance.s3_projects_bucket, filename, bin
  end

  def self.store_in_receipt_bucket filename, bin
    self.store Settings.instance.s3_receipt_bucket, filename, bin
  end

  def self.store bucket, filename, bin
    bucket = AWS.s3.buckets[ bucket   ]
    obj    = bucket.objects[ filename ]
    obj.write bin
  rescue => e
    log.error "Error in store_in_project_bucket"
    log.error e.message
    log.error e.backtrace.join '\n'
  end


  private


    def self.sanitize_filename file_name
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end

end

require 'aws-sdk'

class S3 < Versioneye::Service


  def self.set_aws_crendentials
    Aws.config[:credentials] = Aws::Credentials.new(Settings.instance.aws_access_key_id, Settings.instance.aws_secret_access_key)
    Aws.config[:region] = 'eu-west-1'
    Aws.config
  end


  def self.presigned_url obj_key, bucket_name = Settings.instance.s3_receipt_bucket, expire = 2.minutes.to_i
    presigner = Aws::S3::Presigner.new
    presigner.presigned_url(:get_object,
                        bucket: bucket_name,
                        key: obj_key,
                        expires_in: expire
                        ).to_s
  end


  def self.url_for object, region = 'eu-west-1'
    return nil if object.to_s.empty?

    encoded_name = ''
    bucket_name  = ''

    encoded_name = URI.encode( object.to_s )
    bucket_name  = Settings.instance.s3_projects_bucket
    bucket_name  = Settings.instance.s3_receipt_bucket if object.is_a? Receipt

    s3 = Aws::S3::Resource.new(:region => region)
    bucket = s3.bucket( bucket_name )
    obj = bucket.object( encoded_name )
    obj.public_url
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
  end


  def self.infographic_url_for filename, region = 'eu-west-1'
    return nil if filename.to_s.empty?

    encoded_name = URI.encode( filename )
    s3 = Aws::S3::Resource.new(:region => region)
    bucket = s3.bucket( Settings.instance.s3_infographics_bucket )
    obj = bucket.object( encoded_name )
    obj.public_url
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
  end


  def self.delete filename, bucket_name = Settings.instance.s3_projects_bucket, region = 'eu-west-1'
    return nil if filename.to_s.empty?

    s3 = Aws::S3::Resource.new(:region => region)
    bucket = s3.bucket( bucket_name )
    obj = bucket.object( filename )
    obj.delete
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
  end


  def self.store_in_project_bucket filename, bin, region = 'eu-west-1'
    self.store Settings.instance.s3_projects_bucket, filename, bin, region
  end

  def self.store_in_receipt_bucket filename, bin, region = 'eu-west-1'
    self.store Settings.instance.s3_receipt_bucket, filename, bin, region
  end

  def self.store bucket_name, filename, bin, region = 'eu-west-1'
    s3 = Aws::S3::Resource.new(:region => region)
    bucket = s3.bucket( bucket_name )
    obj = bucket.object( filename )
    obj.put(body: bin)
    obj.etag
  rescue => e
    log.error "Error in store: #{e.message}"
    log.error e.backtrace.join "\n"
  end


  private


    def self.sanitize_filename file_name
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end

end

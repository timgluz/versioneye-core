class DockerImage < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :image_name   , type: String
  field :image_version, type: String

  def self.version name
    image = DockerImage.where(:image_name => name).first
    return image.image_version if image
    nil
  end

end

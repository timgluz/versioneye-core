require 'versioneye/parsers/gemfile_parser'

class MetadataParser < GemfileParser


  def language
    Product::A_LANGUAGE_CHEF
  end

  def type
    Project::A_TYPE_CHEF
  end

  def keyword
    'depends'
  end


end

require 'versioneye/parsers/gemfile_parser'

class BerksfileParser < GemfileParser


  def language
    Product::A_LANGUAGE_CHEF
  end

  def type
    Project::A_TYPE_CHEF
  end

  def keyword
    'cookbook'
  end


end

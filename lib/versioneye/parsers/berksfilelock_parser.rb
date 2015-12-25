require 'versioneye/parsers/common_parser'
require 'versioneye/parsers/gemfilelock_parser'

class BerksfilelockParser < GemfilelockParser


  def language
    Product::A_LANGUAGE_CHEF
  end

  def type
    Project::A_TYPE_CHEF
  end


end

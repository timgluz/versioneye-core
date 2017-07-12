class LanguageService < Versioneye::Service


  A_DISTINCT_LANGUAGES = ["ASP", "ActionScript", "ApacheConf", "Batchfile", "Biicode", "C", "C#", "C++", "CSS", "CSharp", "Chef", "Cirru", "Clojure", "CoffeeScript", "Dart", "Eagle", "Elixir", "Erlang", "GCC Machine Description", "Go", "Groff", "Groovy", "HTML", "Handlebars", "Haskell", "Idris", "Java", "JavaScript", "Jupyter Notebook", "Liquid", "LiveScript", "Lua", "Makefile", "Matlab", "Nix", "Node.JS", "Objective-C", "Opa", "PHP", "Pascal", "Perl", "Processing", "Protocol Buffer", "Puppet", "PureBasic", "PureScript", "Python", "R", "RAML", "Ruby", "Rust", "Scala", "Scheme", "Scilab", "Shell", "Smarty", "Standard ML", "SuperCollider", "Swift", "TypeScript", "Vala", "Vim script", "VimL", "Vue", "XSLT", "wisp"]
  A_KEY = "distinct_languages"


  def self.language_for lang_string
    languages = distinct_languages
    languages << 'nodejs' if !languages.include?('nodejs')
    languages.each do |lang|
      return lang if /\A#{lang}\z/i =~ lang_string || /\A#{lang}\/.*\z/i =~ lang_string
      return lang if lang_string.match(/c\+\+/i)
    end
    nil
  end


  def self.distinct_languages
    languages = cached_languages A_KEY
    if languages.nil? || languages.empty?
      languages = A_DISTINCT_LANGUAGES
      save_in_cache A_KEY, languages
      CommonProducer.new "update_distinct_languages"
    end
    languages
  end


  def self.update_distinct_languages
    languages = Product.all.distinct(:language)
    save_in_cache A_KEY, languages
    languages
  end


  private


    def self.cached_languages key
      cache.get key
    rescue => e
      log.error e.message
      nil
    end

    def self.save_in_cache key, languages
      cache.set( key, languages )
    rescue => e
      log.error e.message
      nil
    end

end

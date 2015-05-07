class LanguageService < Versioneye::Service


  def self.language_for lang_string
    languages = distinct_languages
    languages << 'nodejs'
    languages.each do |lang|
      return lang if /\A#{lang}\z/i =~ lang_string || /\A#{lang}\/.*\z/i =~ lang_string
      return lang if lang_string.match(/c\+\+/i)
    end
    nil
  end


  def self.distinct_languages
    key = "distinct_languages"
    languages = cached_languages key
    if languages.nil? || languages.empty?
      languages = update_distinct_languages   
    end
    languages
  end


  def self.update_distinct_languages 
    key = "distinct_languages"
    languages = Product.all.distinct(:language)
    save_in_cache key, languages
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

class LanguageService < Versioneye::Service

  A_TTL = 7200 # 2 hours

  def self.language_for lang_string
    languages = distinct_languages
    languages << 'nodejs'
    languages.each do |lang|
      return lang if /\A#{lang}\z/i =~ lang_string || /\A#{lang}\/.*\z/i =~ lang_string
      return lang if lang_string.match(/c\+\+/i)
    end
  end


  def self.distinct_languages
    key = "distinct_languages"
    languages = cached_languages key
    if languages.to_s.empty?
      languages = Product.all.distinct(:language)
      save_in_cache key, languages
    end
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
      cache.set( key, languages, A_TTL )
    rescue => e
      log.error e.message
      nil
    end

end

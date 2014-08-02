require 'spec_helper'

describe LanguageService do

  describe 'language_for' do

    it 'returns Java' do
      prod = ProductFactory.create_new 1
      prod.language = "Java"
      prod.save

      LanguageService.language_for("java").should eq("Java")
    end

    it 'returns Java' do
      LanguageService.cache.delete "distinct_languages"

      prod = ProductFactory.create_new 1
      prod.language = "Java"
      prod.save

      prod2 = ProductFactory.create_new 2
      prod2.language = "JavaScript"
      prod2.save

      LanguageService.language_for("javascript").should eq("JavaScript")
    end

  end

end

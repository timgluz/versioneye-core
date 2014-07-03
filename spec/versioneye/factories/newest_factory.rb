FactoryGirl.define do
  sequence :product_name_generator do |n|
    r = Random.rand(0..10000)
    "spec_product_#{n}_#{r}"
  end

  sequence :version_generator do |n|
    n.to_s
  end

  factory :newest do
    name "spec_product"
    version "1"
    language "Ruby"
    prod_key {"#{language.downcase}/#{name}"}
    product_id ""
    created_at 1.day.ago
  end
end

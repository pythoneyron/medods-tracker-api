FactoryBot.define do
  factory :tag do
    association :user

    sequence(:name) { |n| "tag-#{n}" }
    system { false }

    trait :system do
      user { nil }
      system { true }
      name { 'call' }
    end
  end
end

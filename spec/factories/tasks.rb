FactoryBot.define do
  factory :task do
    association :user

    title { "This is a task" }
    description { "This is a description" }
    due_date { Date.current }
    status { 'new' }
  end
end

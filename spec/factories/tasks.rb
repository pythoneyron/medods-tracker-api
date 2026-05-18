FactoryBot.define do
  factory :task do
    association :user

    title { "This is a task" }
    description { "This is a description" }
    due_date { Date.current }
    status { Task::STATUSES.first }

    recurrence_type { 'none' }
    recurrence_config { {} }
    recurrence_starts_on { nil }
    recurrence_ends_on { nil }

    trait :daily do
      recurrence_type { 'daily' }
      recurrence_config { { 'interval' => 1 } }
      recurrence_starts_on { due_date }
    end

    trait :monthly_day do
      recurrence_type { 'monthly_day' }
      recurrence_config { { 'day' => 15 } }
      recurrence_starts_on { due_date }
    end

    trait :specific_dates do
      recurrence_type { 'specific_dates' }
      recurrence_config { { 'dates' => [due_date.iso8601] } }
      recurrence_starts_on { due_date }
    end

    trait :even_days do
      recurrence_type { 'even_days' }
      recurrence_config { {} }
      recurrence_starts_on { due_date }
    end

    trait :odd_days do
      recurrence_type { 'odd_days' }
      recurrence_config { {} }
      recurrence_starts_on { due_date }
    end
  end
end

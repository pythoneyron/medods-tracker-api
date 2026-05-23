FactoryBot.define do
  factory :task_occurrence do
    association :task

    occurrence_date { task&.due_date || Date.current }
    status { Task::STATUSES.first }
  end
end

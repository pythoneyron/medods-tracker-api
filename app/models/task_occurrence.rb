class TaskOccurrence < ApplicationRecord
  STATUSES = Task::STATUSES

  belongs_to :task

  validates :occurrence_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :occurrence_date, uniqueness: { scope: :task_id }
end

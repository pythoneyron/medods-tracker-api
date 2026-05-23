class TaskOccurrence < ApplicationRecord
  STATUSES = %w[planned pending in_progress done cancelled].freeze

  belongs_to :task

  validates :occurrence_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :occurrence_date, uniqueness: { scope: :task_id, message: "already exists for this task" }
end

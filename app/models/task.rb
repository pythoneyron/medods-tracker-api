class Task < ApplicationRecord
  STATUSES = %w[new pending in_progress done cancelled].freeze

  belongs_to :user

  validates :title, presence: true
  validates :due_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
end

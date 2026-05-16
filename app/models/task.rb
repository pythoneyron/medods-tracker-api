class Task < ApplicationRecord
  STATUSES = %w[new pending in_progress done cancelled].freeze

  belongs_to :user

  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags

  validates :title, presence: true
  validates :description, presence: true, allow_blank: true
  validates :due_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
end

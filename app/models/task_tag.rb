class TaskTag < ApplicationRecord
  belongs_to :task
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :task_id, message: 'already assigned to this task' }
  validate :tag_available_for_task_user

  private

  def tag_available_for_task_user
    return if task.blank? || tag.blank?
    return if tag.system?
    return if tag.user_id == task.user_id

    errors.add(:tag, 'is not available for this task')
  end
end

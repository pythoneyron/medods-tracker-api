class Tag < ApplicationRecord
  SYSTEM_NAMES = %w[reporting operations call].freeze

  belongs_to :user, optional: true

  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  validates :name, presence: true, length: { maximum: 100 }
  validates :user, presence: true, unless: :system?
  validates :user, absence: true, if: :system?

  validate :name_uniqueness_within_scope

  before_update :prevent_system_tag_update
  before_destroy :prevent_system_tag_destroy

  scope :available_for, ->(user) { where(system: true).or(where(user: user)) }

  private

  def prevent_system_tag_update
    return unless system?

    errors.add(:base, 'System tag cannot be changed')
    throw(:abort)
  end

  def prevent_system_tag_destroy
    return unless system?

    errors.add(:base, 'System tag cannot be deleted')
    throw(:abort)
  end

  def name_uniqueness_within_scope
    return if name.blank?

    normalized_name = name.downcase

    relation =
      if system?
        Tag.where(system: true)
      else
        Tag.where(user_id: user_id, system: false)
      end

    return unless relation.where('lower(name) = ?', normalized_name).where.not(id: id).exists?

    errors.add(:name, 'has already been taken')
  end
end

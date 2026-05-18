class Task < ApplicationRecord
  STATUSES = %w[planned pending in_progress done cancelled].freeze
  RECURRENCE_TYPES = %w[none daily monthly_day specific_dates even_days odd_days].freeze

  belongs_to :user

  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many :task_occurrences, dependent: :destroy

  validates :title, presence: true
  validates :due_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :recurrence_type, presence: true, inclusion: { in: RECURRENCE_TYPES }

  validate :validate_recurrence_config_type
  validate :validate_recurrence_dates
  validate :validate_recurrence_config

  before_validation :set_default_recurrence_values

  def recurring?
    recurrence_type.present? && recurrence_type != 'none'
  end

  private

  def set_default_recurrence_values
    self.recurrence_type = 'none' if recurrence_type.blank?
    self.recurrence_config = {} if recurrence_config.nil?

    return unless recurring?
    return if recurrence_starts_on.present?

    self.recurrence_starts_on = due_date
  end

  def validate_recurrence_config_type
    return if recurrence_config.is_a?(Hash)

    errors.add(:recurrence_config, 'must be an object')
  end

  def validate_recurrence_dates
    return unless recurring?

    errors.add(:recurrence_starts_on, "can't be blank") if recurrence_starts_on.blank?

    return if recurrence_starts_on.blank?
    return if recurrence_ends_on.blank?
    return if recurrence_ends_on >= recurrence_starts_on

    errors.add(:recurrence_ends_on, 'must be greater than or equal to recurrence_starts_on')
  end

  def validate_recurrence_config
    return unless recurrence_config.is_a?(Hash)

    case recurrence_type
    when 'daily'
      validate_daily_config
    when 'monthly_day'
      validate_monthly_day_config
    when 'specific_dates'
      validate_specific_dates_config
    end
  end

  def validate_daily_config
    interval = integer_config_value('interval')

    if interval.nil?
      errors.add(:recurrence_config, 'interval is required for daily recurrence')
      return
    end

    return if interval.positive?

    errors.add(:recurrence_config, 'interval must be a positive integer')
  end

  def validate_monthly_day_config
    day = integer_config_value('day')

    if day.nil?
      errors.add(:recurrence_config, 'day is required for monthly_day recurrence')
      return
    end

    return if day.between?(1, 31)

    errors.add(:recurrence_config, 'day must be an integer between 1 and 31')
  end

  def validate_specific_dates_config
    dates = recurrence_config['dates']

    unless dates.is_a?(Array) && dates.any?
      errors.add(:recurrence_config, 'dates must be a non-empty array')
      return
    end

    dates.each do |raw_date|
      Date.iso8601(raw_date.to_s)
    rescue ArgumentError
      errors.add(:recurrence_config, "#{raw_date} is not a valid ISO8601 date")
    end
  end

  def integer_config_value(key)
    value = recurrence_config[key]
    return if value.blank?

    return value if value.is_a?(Integer)

    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end
end

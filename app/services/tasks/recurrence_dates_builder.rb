# frozen_string_literal: true

class Tasks::RecurrenceDatesBuilder
  def self.call(task:, date_from:, date_to:)
    new(task: task, date_from: date_from, date_to: date_to).call
  end

  private_class_method :new

  def initialize(task:, date_from:, date_to:)
    @task = task
    @date_from = date_from
    @date_to = date_to
  end

  def call
    return [] unless task.recurring?
    return [] if recurrence_starts_on.blank?
    return [] if date_to < date_from
    return [] if effective_date_range.blank?

    case task.recurrence_type
    when "daily"
      daily_dates
    when "monthly_day"
      monthly_day_dates
    when "specific_dates"
      specific_dates
    when "even_days"
      day_parity_dates(even: true)
    when "odd_days"
      day_parity_dates(even: false)
    else
      []
    end
  end

  private

  attr_reader :task, :date_from, :date_to

  def recurrence_starts_on
    task.recurrence_starts_on
  end

  def recurrence_ends_on
    task.recurrence_ends_on
  end

  def effective_date_range
    @effective_date_range ||= build_effective_date_range
  end

  def build_effective_date_range
    starts_on = [ date_from, recurrence_starts_on ].max
    ends_on = [ date_to, recurrence_ends_on ].compact.min

    return if ends_on < starts_on

    starts_on..ends_on
  end

  def effective_start
    effective_date_range.begin
  end

  def effective_end
    effective_date_range.end
  end

  def daily_dates
    interval = task.recurrence_config.fetch("interval").to_i
    days_offset = (effective_start - recurrence_starts_on).to_i
    remainder = days_offset % interval
    first_date = remainder.zero? ? effective_start : effective_start + (interval - remainder)

    dates = []
    current_date = first_date

    while current_date <= effective_end
      dates << current_date
      current_date += interval
    end

    dates
  end

  def monthly_day_dates
    day = task.recurrence_config.fetch("day").to_i
    dates = []

    current_month = Date.new(effective_start.year, effective_start.month, 1)
    last_month = Date.new(effective_end.year, effective_end.month, 1)

    while current_month <= last_month
      if Date.valid_date?(current_month.year, current_month.month, day)
        candidate = Date.new(current_month.year, current_month.month, day)
        dates << candidate if candidate.between?(effective_start, effective_end)
      end

      current_month = current_month.next_month
    end

    dates
  end

  def specific_dates
    task
      .recurrence_config
      .fetch("dates")
      .map { |raw_date| Date.iso8601(raw_date.to_s) }
      .uniq
      .sort
      .select { |date| date.between?(effective_start, effective_end) }
  end

  def day_parity_dates(even:)
    effective_date_range.select do |date|
      even ? date.day.even? : date.day.odd?
    end
  end
end

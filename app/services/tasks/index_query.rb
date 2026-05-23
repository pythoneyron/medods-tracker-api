class Tasks::IndexQuery
  DEFAULT_WINDOW_DAYS = 30
  MAX_WINDOW_DAYS = 366

  Result = Data.define(:items, :errors, :date_from, :date_to) do
    def success?
      errors.empty?
    end
  end

  def self.call(user:, params:)
    new(user: user, params: params).call
  end

  private_class_method :new

  def initialize(user:, params:)
    @user = user
    @params = params
    @errors = []
  end

  def call
    validate_status_filter

    return failure if errors.any?

    date_window = build_date_window

    return failure if errors.any?

    occurrences_by_key = load_task_occurrences(date_window)

    items = build_items(date_window, occurrences_by_key)
    items = filter_by_status(items)
    items = sort_items(items)

    Result.new(
      items: items,
      errors: [],
      date_from: date_window.begin,
      date_to: date_window.end
    )
  end

  private

  attr_reader :user, :params, :errors

  def failure
    Result.new(items: [], errors: errors, date_from: nil, date_to: nil)
  end

  def validate_status_filter
    return if params[:status].blank?
    return if Task::STATUSES.include?(params[:status])

    errors << "status is not included in the list"
  end

  def build_date_window
    if params[:date].present?
      date = parse_date(params[:date], :date)
      return if errors.any?

      return date..date
    end

    date_from = params[:date_from].present? ? parse_date(params[:date_from], :date_from) : Time.zone.today

    return if errors.any?

    date_to = params[:date_to].present? ? parse_date(params[:date_to], :date_to) : date_from + DEFAULT_WINDOW_DAYS.days

    return if errors.any?

    validate_date_window(date_from, date_to)

    return if errors.any?

    date_from..date_to
  end

  def parse_date(value, field_name)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    errors << "#{field_name} must be a valid ISO8601 date"
    nil
  end

  def validate_date_window(date_from, date_to)
    if date_to < date_from
      errors << "date_to must be greater than or equal to date_from"
      return
    end

    return if (date_to - date_from).to_i <= MAX_WINDOW_DAYS

    errors << "date range cannot be greater than #{MAX_WINDOW_DAYS} days"
  end

  def load_task_occurrences(date_window)
    TaskOccurrence
      .joins(:task)
      .where(tasks: { user_id: user.id })
      .where(occurrence_date: date_window)
      .index_by { |occurrence| [ occurrence.task_id, occurrence.occurrence_date ] }
  end

  def build_items(date_window, occurrences_by_key)
    single_task_items(date_window, occurrences_by_key) +
      recurring_task_items(date_window, occurrences_by_key)
  end

  def single_task_items(date_window, occurrences_by_key)
    single_tasks(date_window).map do |task|
      occurrence_date = task.due_date

      Tasks::OccurrenceBuilder.call(
        task: task,
        occurrence_date: occurrence_date,
        task_occurrence: occurrences_by_key[[ task.id, occurrence_date ]]
      )
    end
  end

  def recurring_task_items(date_window, occurrences_by_key)
    recurring_tasks(date_window).flat_map do |task|
      occurrence_dates = Tasks::RecurrenceDatesBuilder.call(
        task: task,
        date_from: date_window.begin,
        date_to: date_window.end
      )

      occurrence_dates.map do |occurrence_date|
        Tasks::OccurrenceBuilder.call(
          task: task,
          occurrence_date: occurrence_date,
          task_occurrence: occurrences_by_key[[ task.id, occurrence_date ]]
        )
      end
    end
  end

  def single_tasks(date_window)
    user
      .tasks
      .includes(:tags)
      .where(recurrence_type: "none")
      .where(due_date: date_window)
  end

  def recurring_tasks(date_window)
    user
      .tasks
      .includes(:tags)
      .where.not(recurrence_type: "none")
      .where("recurrence_starts_on <= ?", date_window.end)
      .where("recurrence_ends_on IS NULL OR recurrence_ends_on >= ?", date_window.begin)
  end

  def filter_by_status(items)
    return items if params[:status].blank?

    items.select { |item| item.status == params[:status] }
  end

  def sort_items(items)
    items.sort_by { |item| [ item.occurrence_date, item.task_id ] }
  end
end

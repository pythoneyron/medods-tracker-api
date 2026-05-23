class Tasks::OccurrenceStatusUpdater
  Result = Data.define(:item, :errors) do
    def success?
      errors.empty?
    end
  end

  def self.call(user:, task_id:, occurrence_date:, status:)
    new(user: user, task_id: task_id, occurrence_date: occurrence_date, status: status).call
  end

  private_class_method :new

  def initialize(user:, task_id:, occurrence_date:, status:)
    @user = user
    @task_id = task_id
    @raw_occurrence_date = occurrence_date
    @status = status
    @errors = []
  end

  def call
    validate_status

    parsed_date = parse_occurrence_date

    return failure if errors.any?

    task = find_task

    return failure if errors.any?

    validate_recurring_task(task)

    return failure if errors.any?

    validate_task_occurs_on_date(task, parsed_date)

    return failure if errors.any?

    task_occurrence = upsert_task_occurrence(task, parsed_date)

    Result.new(
      item: Tasks::OccurrenceBuilder.call(
        task: task,
        occurrence_date: parsed_date,
        task_occurrence: task_occurrence
      ),
      errors: []
    )
  rescue ActiveRecord::RecordInvalid => e
    errors << e.record.errors.full_messages.to_sentence

    failure
  rescue ActiveRecord::RecordNotUnique
    errors << "occurrence has already been updated, please retry"

    failure
  end

  private

  attr_reader :user, :task_id, :raw_occurrence_date, :status, :errors

  def failure
    Result.new(item: nil, errors: errors)
  end

  def validate_status
    return if TaskOccurrence::STATUSES.include?(status)

    errors << "status is not included in the list"
  end

  def parse_occurrence_date
    Date.iso8601(raw_occurrence_date.to_s)
  rescue ArgumentError
    errors << "occurrence_date must be a valid ISO8601 date"

    nil
  end

  def find_task
    user.tasks.find(task_id)
  rescue ActiveRecord::RecordNotFound
    errors << "task not found"

    nil
  end

  def validate_recurring_task(task)
    return if task.recurring?

    errors << "task is not recurring"
  end

  def validate_task_occurs_on_date(task, occurrence_date)
    dates = Tasks::RecurrenceDatesBuilder.call(
      task: task,
      date_from: occurrence_date,
      date_to: occurrence_date
    )

    return if dates.include?(occurrence_date)

    errors << "task does not occur on this date"
  end

  def upsert_task_occurrence(task, occurrence_date)
    TaskOccurrence.transaction do
      task_occurrence = task.task_occurrences.find_or_initialize_by(
        occurrence_date: occurrence_date
      )
      task_occurrence.status = status

      task_occurrence.save! if task_occurrence.new_record? || task_occurrence.changed?

      task_occurrence
    end
  end
end

class Tasks::OccurrenceBuilder
  def self.call(task:, occurrence_date:, task_occurrence: nil)
    new(
      task: task,
      occurrence_date: occurrence_date,
      task_occurrence: task_occurrence
    ).call
  end

  private_class_method :new

  def initialize(task:, occurrence_date:, task_occurrence: nil)
    @task = task
    @occurrence_date = occurrence_date
    @task_occurrence = task_occurrence
  end

  def call
    Tasks::OccurrenceItem.new(
      task: task,
      occurrence_date: occurrence_date,
      status: resolved_status,
      task_occurrence: task_occurrence
    )
  end

  private

  attr_reader :task, :occurrence_date, :task_occurrence

  def resolved_status
    task_occurrence&.status || task.status
  end
end

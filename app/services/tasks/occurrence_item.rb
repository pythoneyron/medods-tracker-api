module Tasks
  OccurrenceItem = Data.define(
    :task,
    :occurrence_date,
    :status,
    :task_occurrence
  ) do
    def task_id
      task.id
    end

    def title
      task.title
    end

    def description
      task.description
    end

    def due_date
      task.due_date
    end

    def recurrence_type
      task.recurrence_type
    end

    def recurrence_config
      task.recurrence_config
    end

    def recurrence_starts_on
      task.recurrence_starts_on
    end

    def recurrence_ends_on
      task.recurrence_ends_on
    end

    def recurring?
      task.recurring?
    end

    def tags
      task.tags
    end

    def created_at
      task.created_at
    end

    def updated_at
      task_occurrence&.updated_at || task.updated_at
    end
  end
end

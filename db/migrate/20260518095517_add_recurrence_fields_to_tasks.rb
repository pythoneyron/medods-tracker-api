# frozen_string_literal: true

class AddRecurrenceFieldsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :recurrence_type, :string, null: false, default: 'none'
    add_column :tasks, :recurrence_config, :jsonb, null: false, default: {}
    add_column :tasks, :recurrence_starts_on, :date
    add_column :tasks, :recurrence_ends_on, :date

    add_index :tasks, [:user_id, :recurrence_type]
    add_index :tasks, [:user_id, :recurrence_starts_on]
    add_index :tasks, [:user_id, :recurrence_ends_on]

    add_check_constraint(
      :tasks,
      "recurrence_type IN ('none', 'daily', 'monthly_day', 'specific_dates', 'even_days', 'odd_days')",
      name: 'task_recurrence_type_allowed'
    )

    add_check_constraint(
      :tasks,
      "jsonb_typeof(recurrence_config) = 'object'",
      name: 'task_recurrence_config_object'
    )

    add_check_constraint(
      :tasks,
      "recurrence_type = 'none' OR recurrence_starts_on IS NOT NULL",
      name: 'recurring_task_starts_on_required'
    )

    add_check_constraint(
      :tasks,
      "recurrence_type != 'none' OR (recurrence_starts_on IS NULL AND recurrence_ends_on IS NULL)",
      name: 'non_recurring_task_has_no_recurrence_period'
    )

    add_check_constraint(
      :tasks,
      'recurrence_ends_on IS NULL OR recurrence_starts_on IS NULL OR recurrence_ends_on >= recurrence_starts_on',
      name: 'task_recurrence_ends_on_after_starts_on'
    )
  end
end

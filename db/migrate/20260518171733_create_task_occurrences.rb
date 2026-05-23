# frozen_string_literal: true

class CreateTaskOccurrences < ActiveRecord::Migration[8.1]
  def change
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: true, index: false

      t.date :occurrence_date, null: false
      t.string :status, null: false, default: 'planned'

      t.timestamps null: false
    end

    add_index(
      :task_occurrences,
      [ :task_id, :occurrence_date ],
      unique: true,
      name: 'index_task_occurrences_on_task_and_date'
    )

    add_index(
      :task_occurrences,
      [ :occurrence_date, :status ],
      name: 'index_task_occurrences_on_date_and_status'
    )

    add_check_constraint(
      :task_occurrences,
      "status IN ('planned', 'pending', 'in_progress', 'done', 'cancelled')",
      name: 'task_occurrence_status_allowed'
    )
  end
end

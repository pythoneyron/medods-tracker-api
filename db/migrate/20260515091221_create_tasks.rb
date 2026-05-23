class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true

      t.string :title, null: false
      t.text :description, null: false
      t.date :due_date, null: false
      t.string :status, null: false, default: "planned"

      t.timestamps
    end

    add_index :tasks, :due_date
    add_index :tasks, :status
    add_index :tasks, [ :user_id, :due_date ]
    add_index :tasks, [ :user_id, :status ]

    add_check_constraint :tasks, "status IN ('planned', 'pending', 'in_progress', 'done', 'cancelled')",
                         name: "task_status_allowed"
  end
end

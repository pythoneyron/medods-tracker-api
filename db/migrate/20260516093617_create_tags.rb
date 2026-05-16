class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :user, null: true, foreign_key: true

      t.string :name, null: false
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_index :tags, :system

    add_index :tags, "lower(name)", unique: true,
              where: "system = TRUE", name: "index_system_tags_on_lower_name"

    add_index :tags, "user_id, lower(name)", unique: true,
              where: "system = FALSE", name: "index_user_tags_on_user_id_and_lower_name"

    add_check_constraint :tags, "(system = TRUE AND user_id IS NULL) OR (system = FALSE AND user_id IS NOT NULL)",
                         name: 'tags_system_user_consistency'

    add_check_constraint :tags, "system = FALSE OR lower(name) IN ('reporting', 'operations', 'call')",
                         name: "system_tag_name_allowed"
  end
end

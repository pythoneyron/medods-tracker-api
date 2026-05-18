# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_18_171733) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index "lower((name)::text)", name: "index_system_tags_on_lower_name", unique: true, where: "(system = true)"
    t.index "user_id, lower((name)::text)", name: "index_user_tags_on_user_id_and_lower_name", unique: true, where: "(system = false)"
    t.index ["system"], name: "index_tags_on_system"
    t.index ["user_id"], name: "index_tags_on_user_id"
    t.check_constraint "system = false OR (lower(name::text) = ANY (ARRAY['reporting'::text, 'operations'::text, 'call'::text]))", name: "system_tag_name_allowed"
    t.check_constraint "system = true AND user_id IS NULL OR system = false AND user_id IS NOT NULL", name: "tags_system_user_consistency"
  end

  create_table "task_occurrences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "occurrence_date", null: false
    t.string "status", default: "planned", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["occurrence_date", "status"], name: "index_task_occurrences_on_date_and_status"
    t.index ["task_id", "occurrence_date"], name: "index_task_occurrences_on_task_and_date", unique: true
    t.check_constraint "status::text = ANY (ARRAY['planned'::character varying::text, 'pending'::character varying::text, 'in_progress'::character varying::text, 'done'::character varying::text, 'cancelled'::character varying::text])", name: "task_occurrence_status_allowed"
  end

  create_table "task_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_task_tags_on_tag_id"
    t.index ["task_id", "tag_id"], name: "index_task_tags_on_task_id_and_tag_id", unique: true
    t.index ["task_id"], name: "index_task_tags_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.date "due_date", null: false
    t.jsonb "recurrence_config", default: {}, null: false
    t.date "recurrence_ends_on"
    t.date "recurrence_starts_on"
    t.string "recurrence_type", default: "none", null: false
    t.string "status", default: "planned", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["user_id", "due_date"], name: "index_tasks_on_user_id_and_due_date"
    t.index ["user_id", "recurrence_ends_on"], name: "index_tasks_on_user_id_and_recurrence_ends_on"
    t.index ["user_id", "recurrence_starts_on"], name: "index_tasks_on_user_id_and_recurrence_starts_on"
    t.index ["user_id", "recurrence_type"], name: "index_tasks_on_user_id_and_recurrence_type"
    t.index ["user_id", "status"], name: "index_tasks_on_user_id_and_status"
    t.index ["user_id"], name: "index_tasks_on_user_id"
    t.check_constraint "jsonb_typeof(recurrence_config) = 'object'::text", name: "task_recurrence_config_object"
    t.check_constraint "recurrence_ends_on IS NULL OR recurrence_starts_on IS NULL OR recurrence_ends_on >= recurrence_starts_on", name: "task_recurrence_ends_on_after_starts_on"
    t.check_constraint "recurrence_type::text <> 'none'::text OR recurrence_starts_on IS NULL AND recurrence_ends_on IS NULL", name: "non_recurring_task_has_no_recurrence_period"
    t.check_constraint "recurrence_type::text = 'none'::text OR recurrence_starts_on IS NOT NULL", name: "recurring_task_starts_on_required"
    t.check_constraint "recurrence_type::text = ANY (ARRAY['none'::character varying::text, 'daily'::character varying::text, 'monthly_day'::character varying::text, 'specific_dates'::character varying::text, 'even_days'::character varying::text, 'odd_days'::character varying::text])", name: "task_recurrence_type_allowed"
    t.check_constraint "status::text = ANY (ARRAY['planned'::character varying::text, 'pending'::character varying::text, 'in_progress'::character varying::text, 'done'::character varying::text, 'cancelled'::character varying::text])", name: "task_status_allowed"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "tags", "users"
  add_foreign_key "task_occurrences", "tasks", on_delete: :cascade
  add_foreign_key "task_tags", "tags"
  add_foreign_key "task_tags", "tasks"
  add_foreign_key "tasks", "users"
end

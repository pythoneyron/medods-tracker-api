# frozen_string_literal: true

require "faker"

Faker::Config.locale = "en"
Faker::Config.random = Random.new(20260524)

DEMO_PASSWORD = "password123"
SEED_START_DATE = Date.iso8601("2026-05-20")

DEMO_USERS = [
  "doctor@example.com",
  "admin@example.com",
  "nurse@example.com"
].freeze

USER_TAG_NAMES = [
  "Rounds",
  "Reports",
  "Calls",
  "Discharge",
  "Medication",
  "Appointments"
].freeze

SINGLE_TASKS = [
  [ "Call patient", "planned", 0 ],
  [ "Prepare medical report", "pending", 1 ],
  [ "Review lab results", "in_progress", 2 ],
  [ "Schedule appointment", "done", 3 ],
  [ "Coordinate discharge", "cancelled", 4 ]
].freeze

def find_or_create_system_tag!(name)
  Tag.where(system: true).where("LOWER(name) = ?", name.downcase).first ||
    Tag.create!(name: name, system: true)
end

def find_or_create_user_tag!(user, name)
  Tag.where(user: user, system: false).where("LOWER(name) = ?", name.downcase).first ||
    user.tags.create!(name: name)
end

def find_or_create_demo_user!(email)
  user = User.find_or_initialize_by(email: email)
  user.password = DEMO_PASSWORD
  user.password_confirmation = DEMO_PASSWORD
  user.save!
  user
end

def create_or_update_task!(user:, title:, attributes:, tags:)
  task = user.tasks.find_or_initialize_by(title: title)
  task.assign_attributes(attributes)
  task.save!

  tags.each do |tag|
    TaskTag.find_or_create_by!(task: task, tag: tag)
  end

  task
end

def create_or_update_task_occurrence!(task:, occurrence_date:, status:)
  task_occurrence = task.task_occurrences.find_or_initialize_by(
    occurrence_date: occurrence_date
  )
  task_occurrence.status = status
  task_occurrence.save!
  task_occurrence
end

def task_description(prefix)
  "#{prefix}. #{Faker::Lorem.paragraph(sentence_count: 2)}"
end

system_tags = Tag::SYSTEM_NAMES.map { |name| find_or_create_system_tag!(name) }
users = DEMO_USERS.map { |email| find_or_create_demo_user!(email) }

ActiveRecord::Base.transaction do
  users.each_with_index do |user, user_index|
    user_tags = USER_TAG_NAMES.map do |tag_name|
      find_or_create_user_tag!(user, "#{tag_name} #{user_index + 1}")
    end

    available_tags = system_tags + user_tags

    SINGLE_TASKS.each_with_index do |(name, status, days_offset), task_index|
      create_or_update_task!(
        user: user,
        title: "#{name} - #{user.email}",
        attributes: {
          description: task_description("Seeded non-recurring task"),
          due_date: SEED_START_DATE + days_offset.days,
          status: status,
          recurrence_type: "none",
          recurrence_config: {},
          recurrence_starts_on: nil,
          recurrence_ends_on: nil
        },
        tags: available_tags.rotate(task_index).first(3)
      )
    end

    daily_task = create_or_update_task!(
      user: user,
      title: "Daily ward round - #{user.email}",
      attributes: {
        description: task_description("Daily recurring task for occurrence status checks"),
        due_date: SEED_START_DATE,
        status: "planned",
        recurrence_type: "daily",
        recurrence_config: { "interval" => 1 },
        recurrence_starts_on: SEED_START_DATE,
        recurrence_ends_on: SEED_START_DATE + 10.days
      },
      tags: [ system_tags.first, user_tags.first ]
    )

    create_or_update_task_occurrence!(
      task: daily_task,
      occurrence_date: SEED_START_DATE + 1.day,
      status: "done"
    )
    create_or_update_task_occurrence!(
      task: daily_task,
      occurrence_date: SEED_START_DATE + 2.days,
      status: "in_progress"
    )

    monthly_task = create_or_update_task!(
      user: user,
      title: "Monthly report review - #{user.email}",
      attributes: {
        description: task_description("Monthly recurring task"),
        due_date: SEED_START_DATE + 5.days,
        status: "pending",
        recurrence_type: "monthly_day",
        recurrence_config: { "day" => 25 },
        recurrence_starts_on: SEED_START_DATE,
        recurrence_ends_on: SEED_START_DATE + 3.months
      },
      tags: [ system_tags.second, user_tags.second ]
    )

    create_or_update_task_occurrence!(
      task: monthly_task,
      occurrence_date: Date.iso8601("2026-05-25"),
      status: "done"
    )

    create_or_update_task!(
      user: user,
      title: "Specific dates medication audit - #{user.email}",
      attributes: {
        description: task_description("Specific dates recurring task"),
        due_date: SEED_START_DATE + 1.day,
        status: "planned",
        recurrence_type: "specific_dates",
        recurrence_config: {
          "dates" => [
            "2026-05-21",
            "2026-05-28",
            "2026-06-04"
          ]
        },
        recurrence_starts_on: SEED_START_DATE,
        recurrence_ends_on: SEED_START_DATE + 20.days
      },
      tags: [ system_tags.third, user_tags.third ]
    )

    create_or_update_task!(
      user: user,
      title: "Even day patient follow-up - #{user.email}",
      attributes: {
        description: task_description("Even day recurring task"),
        due_date: SEED_START_DATE,
        status: "planned",
        recurrence_type: "even_days",
        recurrence_config: {},
        recurrence_starts_on: SEED_START_DATE,
        recurrence_ends_on: SEED_START_DATE + 10.days
      },
      tags: [ user_tags.fourth ]
    )

    create_or_update_task!(
      user: user,
      title: "Odd day clinic callback - #{user.email}",
      attributes: {
        description: task_description("Odd day recurring task"),
        due_date: SEED_START_DATE + 1.day,
        status: "pending",
        recurrence_type: "odd_days",
        recurrence_config: {},
        recurrence_starts_on: SEED_START_DATE,
        recurrence_ends_on: SEED_START_DATE + 10.days
      },
      tags: [ user_tags.fifth ]
    )
  end
end

puts(
  [
    "Seeded demo credentials: #{DEMO_USERS.join(', ')} / #{DEMO_PASSWORD}",
    "#{User.count} users",
    "#{Task.count} tasks",
    "#{Tag.count} tags",
    "#{TaskTag.count} task tags",
    "#{TaskOccurrence.count} task occurrences"
  ].join(", ")
)

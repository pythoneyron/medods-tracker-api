# frozen_string_literal: true

require 'faker'

Faker::Config.locale = 'en'
Faker::Config.random = Random.new(20260517)

DEMO_PASSWORD = 'password123'
TASKS_PER_USER = 10
USER_TAGS_PER_USER = 6

DEMO_USERS = [
  'doctor@example.com',
  'admin@example.com',
  'nurse@example.com'
].freeze

TASK_TEMPLATES = [
  'Call patient',
  'Prepare medical report',
  'Review lab results',
  'Schedule appointment',
  'Perform ward round',
  'Prepare surgery checklist',
  'Update patient record',
  'Coordinate discharge',
  'Check medication plan',
  'Follow up with clinic'
].freeze

def find_or_create_system_tag!(name)
  Tag.where(system: true).where('lower(name) = ?', name.downcase).first ||
    Tag.create!(name: name, system: true)
end

def find_or_create_user_tag!(user, name)
  normalized_name = name.strip

  Tag.where(user: user, system: false).where('lower(name) = ?', normalized_name.downcase).first ||
    user.tags.create!(name: normalized_name)
end

def find_or_create_demo_user!(email)
  user = User.find_or_initialize_by(email: email)
  user.password = DEMO_PASSWORD
  user.password_confirmation = DEMO_PASSWORD
  user.save!
  user
end

system_tags = Tag::SYSTEM_NAMES.map { |name| find_or_create_system_tag!(name) }
users = DEMO_USERS.map { |email| find_or_create_demo_user!(email) }

users.each_with_index do |user, user_index|
  Faker::UniqueGenerator.clear

  user_tags = Array.new(USER_TAGS_PER_USER) do |tag_index|
    name = "#{Faker::Job.unique.key_skill} #{user_index + 1}-#{tag_index + 1}"

    find_or_create_user_tag!(user, name)
  end

  available_tags = system_tags + user_tags

  TASKS_PER_USER.times do |task_index|
    title = "#{TASK_TEMPLATES[task_index]}: #{Faker::Name.name}"
    task = user.tasks.find_or_initialize_by(title: title)

    task.assign_attributes(
      description: Faker::Lorem.paragraph(sentence_count: 2),
      due_date: Faker::Date.between(from: 7.days.ago, to: 30.days.from_now),
      status: Task::STATUSES[(task_index + user_index) % Task::STATUSES.size]
    )
    task.save!

    tags_for_task = available_tags.rotate(task_index).first(2 + (task_index % 2))
    tags_for_task.each do |tag|
      TaskTag.find_or_create_by!(task: task, tag: tag)
    end
  end
end

puts(
  [
    "Seeded #{User.count} users",
    "#{Task.count} tasks",
    "#{Tag.count} tags",
    "#{TaskTag.count} task tags"
  ].join(', ')
)

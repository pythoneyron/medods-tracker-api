json.id task.id
json.title task.title
json.description task.description
json.due_date task.due_date&.iso8601
json.status task.status

json.recurrence_type task.recurrence_type
json.recurrence_config task.recurrence_config
json.recurrence_starts_on task.recurrence_starts_on&.iso8601
json.recurrence_ends_on task.recurrence_ends_on&.iso8601
json.recurring task.recurring?

json.tags task.tags do |tag|
  json.partial! "api/v1/tags/tag", tag: tag
end

json.created_at task.created_at&.iso8601
json.updated_at task.updated_at&.iso8601

json.id task_item.task_id
json.task_id task_item.task_id
json.occurrence_date task_item.occurrence_date&.iso8601

json.title task_item.title
json.description task_item.description
json.due_date task_item.due_date&.iso8601
json.status task_item.status

json.recurring task_item.recurring?
json.recurrence_type task_item.recurrence_type
json.recurrence_config task_item.recurrence_config
json.recurrence_starts_on task_item.recurrence_starts_on&.iso8601
json.recurrence_ends_on task_item.recurrence_ends_on&.iso8601

json.tags task_item.tags do |tag|
  json.partial! 'api/v1/tags/tag', tag: tag
end

json.created_at task_item.created_at&.iso8601
json.updated_at task_item.updated_at&.iso8601

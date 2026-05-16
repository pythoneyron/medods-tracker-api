json.id task.id
json.title task.title
json.description task.description
json.due_date task.due_date&.iso8601
json.status task.status

json.tags task.tags do |tag|
  json.partial! 'api/v1/tags/tag', tag: tag
end

json.created_at task.created_at&.iso8601
json.updated_at task.updated_at&.iso8601

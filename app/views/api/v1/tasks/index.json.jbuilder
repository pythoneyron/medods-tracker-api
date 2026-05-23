json.tasks @task_items do |task_item|
  json.partial! 'api/v1/tasks/task_item', task_item: task_item
end

json.meta @pagination[:meta]
json.links @pagination[:links]

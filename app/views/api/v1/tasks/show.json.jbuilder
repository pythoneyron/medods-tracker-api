json.task do
  json.partial! 'api/v1/tasks/task', task: @task
end

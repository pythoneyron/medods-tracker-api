json.tags @tags do |tag|
  json.partial! "api/v1/tags/tag", tag: tag
end

json.meta @pagination[:meta]
json.links @pagination[:links]

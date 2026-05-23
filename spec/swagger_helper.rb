# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Medods Tracker API',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Local development server'
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          ErrorResponse: {
            type: :object,
            required: %w[errors],
            properties: {
              errors: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: { type: :string }
                }
              }
            }
          },
          UnauthorizedResponse: {
            type: :object,
            required: %w[error],
            properties: {
              error: { type: :string }
            }
          },
          User: {
            type: :object,
            required: %w[id email created_at updated_at],
            properties: {
              id: { type: :integer },
              email: { type: :string, format: :email },
              created_at: { type: :string, format: :'date-time', nullable: true },
              updated_at: { type: :string, format: :'date-time', nullable: true }
            }
          },
          UserResponse: {
            type: :object,
            required: %w[user],
            properties: {
              user: { '$ref' => '#/components/schemas/User' }
            }
          },
          Tag: {
            type: :object,
            required: %w[id name system created_at updated_at],
            properties: {
              id: { type: :integer },
              name: { type: :string },
              system: { type: :boolean },
              created_at: { type: :string, format: :'date-time', nullable: true },
              updated_at: { type: :string, format: :'date-time', nullable: true }
            }
          },
          TagResponse: {
            type: :object,
            required: %w[tag],
            properties: {
              tag: { '$ref' => '#/components/schemas/Tag' }
            }
          },
          TagsResponse: {
            type: :object,
            required: %w[tags],
            properties: {
              tags: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Tag' }
              }
            }
          },
          Task: {
            type: :object,
            required: %w[
              id title description due_date status recurrence_type recurrence_config
              recurrence_starts_on recurrence_ends_on recurring tags created_at updated_at
            ],
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              due_date: { type: :string, format: :date },
              status: {
                type: :string,
                enum: Task::STATUSES
              },
              recurrence_type: {
                type: :string,
                enum: Task::RECURRENCE_TYPES
              },
              recurrence_config: {
                type: :object,
                additionalProperties: true
              },
              recurrence_starts_on: { type: :string, format: :date, nullable: true },
              recurrence_ends_on: { type: :string, format: :date, nullable: true },
              recurring: { type: :boolean },
              tags: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Tag' }
              },
              created_at: { type: :string, format: :'date-time', nullable: true },
              updated_at: { type: :string, format: :'date-time', nullable: true }
            }
          },
          TaskResponse: {
            type: :object,
            required: %w[task],
            properties: {
              task: { '$ref' => '#/components/schemas/Task' }
            }
          },
          TaskItem: {
            type: :object,
            required: %w[
              id task_id occurrence_date title description due_date status recurring recurrence_type
              recurrence_config recurrence_starts_on recurrence_ends_on tags created_at updated_at
            ],
            properties: {
              id: { type: :integer, description: 'Task id kept for backward compatibility' },
              task_id: { type: :integer },
              occurrence_date: { type: :string, format: :date },
              title: { type: :string },
              description: { type: :string, nullable: true },
              due_date: { type: :string, format: :date },
              status: {
                type: :string,
                enum: Task::STATUSES
              },
              recurring: { type: :boolean },
              recurrence_type: {
                type: :string,
                enum: Task::RECURRENCE_TYPES
              },
              recurrence_config: {
                type: :object,
                additionalProperties: true
              },
              recurrence_starts_on: { type: :string, format: :date, nullable: true },
              recurrence_ends_on: { type: :string, format: :date, nullable: true },
              tags: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Tag' }
              },
              created_at: { type: :string, format: :'date-time', nullable: true },
              updated_at: { type: :string, format: :'date-time', nullable: true }
            }
          },
          TaskItemResponse: {
            type: :object,
            required: %w[task],
            properties: {
              task: { '$ref' => '#/components/schemas/TaskItem' }
            }
          },
          TasksResponse: {
            type: :object,
            required: %w[tasks meta links],
            properties: {
              tasks: {
                type: :array,
                items: { '$ref' => '#/components/schemas/TaskItem' }
              },
              meta: {
                type: :object,
                additionalProperties: true
              },
              links: {
                type: :object,
                additionalProperties: true
              }
            }
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end

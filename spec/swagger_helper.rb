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
            required: %w[id title description due_date status tags created_at updated_at],
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              due_date: { type: :string, format: :date },
              status: {
                type: :string,
                enum: %w[new pending in_progress done cancelled]
              },
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
          TasksResponse: {
            type: :object,
            required: %w[tasks],
            properties: {
              tasks: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Task' }
              }
            }
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end

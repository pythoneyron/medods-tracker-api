# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1 Swagger', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:Authorization) { auth_headers(user).fetch('Authorization') }

  path '/api/v1/users' do
    post 'Create user' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[user],
        properties: {
          user: {
            type: :object,
            required: %w[email password password_confirmation],
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string, format: :password },
              password_confirmation: { type: :string, format: :password }
            }
          }
        }
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/UserResponse'

        let(:payload) do
          {
            user: {
              email: 'swagger_user@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        run_test!
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:payload) do
          {
            user: {
              email: 'invalid',
              password: 'short',
              password_confirmation: 'mismatch'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/sign_in' do
    post 'Sign in user' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[user],
        properties: {
          user: {
            type: :object,
            required: %w[email password],
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string, format: :password }
            }
          }
        }
      }

      response '200', 'signed in' do
        schema '$ref' => '#/components/schemas/UserResponse'

        let!(:existing_user) do
          FactoryBot.create(:user, email: 'swagger_member@example.com', password: 'password123')
        end

        let(:payload) do
          {
            user: {
              email: existing_user.email,
              password: 'password123'
            }
          }
        end

        run_test!
      end

      response '401', 'invalid credentials' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let!(:existing_user) do
          FactoryBot.create(:user, email: 'swagger_invalid_member@example.com', password: 'password123')
        end

        let(:payload) do
          {
            user: {
              email: existing_user.email,
              password: 'wrong-password'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/sign_out' do
    delete 'Sign out user' do
      tags 'Auth'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'signed out' do
        schema type: :object,
               required: %w[message],
               properties: {
                 message: { type: :string }
               }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedResponse'
        let(:Authorization) { nil }

        run_test!
      end
    end
  end

  path '/api/v1/tasks' do
    get 'List tasks' do
      tags 'Tasks'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :status, in: :query, required: false, schema: {
        type: :string,
        enum: Task::STATUSES
      }
      parameter name: :date, in: :query, required: false, schema: { type: :string, format: :date }
      parameter name: :date_from, in: :query, required: false, schema: { type: :string, format: :date }
      parameter name: :date_to, in: :query, required: false, schema: { type: :string, format: :date }
      parameter name: :'page[number]', in: :query, required: false, schema: {
        type: :integer,
        minimum: 1,
        default: 1
      }
      parameter name: :'page[size]', in: :query, required: false, schema: {
        type: :integer,
        minimum: 1,
        maximum: Pagy::OPTIONS.fetch(:max_limit),
        default: Pagy::OPTIONS.fetch(:limit)
      }

      response '200', 'tasks list' do
        schema '$ref' => '#/components/schemas/TasksResponse'

        before do
          FactoryBot.create(:task, user: user, title: 'Swagger task')
        end

        run_test!
      end

      response '400', 'invalid query params' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:date_from) { '2026-05-22' }
        let(:date_to) { '2026-05-21' }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedResponse'
        let(:Authorization) { nil }

        run_test!
      end
    end

    post 'Create task' do
      tags 'Tasks'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[task],
        properties: {
          task: {
            type: :object,
            required: %w[title description due_date status],
            properties: {
              title: { type: :string },
              description: { type: :string },
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
              recurrence_ends_on: { type: :string, format: :date, nullable: true }
            }
          }
        }
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/TaskResponse'

        let(:payload) do
          {
            task: {
              title: 'Prepare report',
              description: 'Quarterly planning',
              due_date: '2026-05-25',
              status: 'pending'
            }
          }
        end

        run_test!
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:payload) do
          {
            task: {
              title: '',
              description: 'Invalid task',
              due_date: '2026-05-25',
              status: 'pending'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/tasks/{id}' do
    parameter name: :id, in: :path, required: true, schema: { type: :integer }

    get 'Show task' do
      tags 'Tasks'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'task found' do
        schema '$ref' => '#/components/schemas/TaskResponse'

        let(:task) { FactoryBot.create(:task, user: user) }
        let(:id) { task.id }

        run_test!
      end

      response '404', 'task not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:id) { 0 }

        run_test!
      end
    end

    patch 'Update task' do
      tags 'Tasks'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[task],
        properties: {
          task: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
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
              recurrence_ends_on: { type: :string, format: :date, nullable: true }
            }
          }
        }
      }

      response '200', 'updated' do
        schema '$ref' => '#/components/schemas/TaskResponse'

        let(:task) { FactoryBot.create(:task, user: user) }
        let(:id) { task.id }
        let(:payload) { { task: { title: 'Updated task', status: 'done' } } }

        run_test!
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:task) { FactoryBot.create(:task, user: user) }
        let(:id) { task.id }
        let(:payload) { { task: { status: 'archived' } } }

        run_test!
      end
    end

    delete 'Delete task' do
      tags 'Tasks'
      security [{ bearerAuth: [] }]

      response '204', 'deleted' do
        let(:task) { FactoryBot.create(:task, user: user) }
        let(:id) { task.id }

        run_test!
      end

      response '404', 'task not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/tags' do
    get 'List tags' do
      tags 'Tags'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'tags list' do
        schema '$ref' => '#/components/schemas/TagsResponse'

        before do
          FactoryBot.create(:tag, user: user, name: 'Swagger tag')
          FactoryBot.create(:tag, user: nil, system: true, name: 'reporting')
        end

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/UnauthorizedResponse'
        let(:Authorization) { nil }

        run_test!
      end
    end

    post 'Create tag' do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[tag],
        properties: {
          tag: {
            type: :object,
            required: %w[name],
            properties: {
              name: { type: :string }
            }
          }
        }
      }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/TagResponse'

        let(:payload) { { tag: { name: 'Discharge planning' } } }

        run_test!
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:payload) { { tag: { name: '' } } }

        run_test!
      end
    end
  end

  path '/api/v1/tags/{id}' do
    parameter name: :id, in: :path, required: true, schema: { type: :integer }

    get 'Show tag' do
      tags 'Tags'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'tag found' do
        schema '$ref' => '#/components/schemas/TagResponse'

        let(:tag) { FactoryBot.create(:tag, user: user, name: 'Appointments') }
        let(:id) { tag.id }

        run_test!
      end

      response '404', 'tag not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:id) { 0 }

        run_test!
      end
    end

    patch 'Update tag' do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[tag],
        properties: {
          tag: {
            type: :object,
            properties: {
              name: { type: :string }
            }
          }
        }
      }

      response '200', 'updated' do
        schema '$ref' => '#/components/schemas/TagResponse'

        let(:tag) { FactoryBot.create(:tag, user: user, name: 'Old tag') }
        let(:id) { tag.id }
        let(:payload) { { tag: { name: 'Updated tag' } } }

        run_test!
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:tag) { FactoryBot.create(:tag, user: user, name: 'Tag') }
        let(:id) { tag.id }
        let(:payload) { { tag: { name: '' } } }

        run_test!
      end
    end

    delete 'Delete tag' do
      tags 'Tags'
      security [{ bearerAuth: [] }]

      response '204', 'deleted' do
        let(:tag) { FactoryBot.create(:tag, user: user) }
        let(:id) { tag.id }

        run_test!
      end

      response '404', 'tag not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/tasks/{task_id}/tags' do
    parameter name: :task_id, in: :path, required: true, schema: { type: :integer }

    post 'Attach tag to task' do
      tags 'Task tags'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[tag],
        properties: {
          tag: {
            type: :object,
            required: %w[id],
            properties: {
              id: { type: :integer }
            }
          }
        }
      }

      response '201', 'attached' do
        schema '$ref' => '#/components/schemas/TaskResponse'

        let(:task) { FactoryBot.create(:task, user: user) }
        let(:tag) { FactoryBot.create(:tag, user: user, name: 'Rounds') }
        let(:task_id) { task.id }
        let(:payload) { { tag: { id: tag.id } } }

        run_test!
      end

      response '404', 'task or tag not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:task_id) { 0 }
        let(:payload) { { tag: { id: 0 } } }

        run_test!
      end
    end
  end

  path '/api/v1/tasks/{task_id}/tags/{tag_id}' do
    parameter name: :task_id, in: :path, required: true, schema: { type: :integer }
    parameter name: :tag_id, in: :path, required: true, schema: { type: :integer }

    delete 'Detach tag from task' do
      tags 'Task tags'
      security [{ bearerAuth: [] }]

      response '204', 'detached' do
        let(:task) { FactoryBot.create(:task, user: user) }
        let(:tag) { FactoryBot.create(:tag, user: user, name: 'Calls') }
        let!(:task_tag) { FactoryBot.create(:task_tag, task: task, tag: tag) }
        let(:task_id) { task.id }
        let(:tag_id) { tag.id }

        run_test!
      end

      response '404', 'task tag not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:task_id) { 0 }
        let(:tag_id) { 0 }

        run_test!
      end
    end
  end
end

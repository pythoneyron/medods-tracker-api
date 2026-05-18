require 'rails_helper'

RSpec.describe 'Api::V1::Tasks', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:headers) { auth_headers(user) }
  let(:json_headers) { { 'Accept' => 'application/json' } }

  describe 'GET /api/v1/tasks' do
    it 'returns unauthorized without a token' do
      get api_v1_tasks_path, headers: json_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns only the current user tasks ordered by due_date and created_at' do
      other_task = FactoryBot.create(:task, title: 'Other user task')

      first_task = nil
      second_task = nil
      third_task = nil

      travel_to(Time.zone.parse('2026-05-15 09:00:00')) do
        second_task = FactoryBot.create(:task, user: user, title: 'Second task', due_date: Date.iso8601('2026-05-20'))
      end

      travel_to(Time.zone.parse('2026-05-15 10:00:00')) do
        third_task = FactoryBot.create(:task, user: user, title: 'Third task', due_date: Date.iso8601('2026-05-20'))
      end

      travel_to(Time.zone.parse('2026-05-15 11:00:00')) do
        first_task = FactoryBot.create(:task, user: user, title: 'First task', due_date: Date.iso8601('2026-05-18'))
      end

      get api_v1_tasks_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(task_ids_from_response).to eq([first_task.id, second_task.id, third_task.id])
      expect(task_ids_from_response).not_to include(other_task.id)
    end

    it 'filters tasks by status' do
      matching_task = FactoryBot.create(:task, user: user, status: 'pending')
      FactoryBot.create(:task, user: user, status: 'done')
      FactoryBot.create(:task, status: 'pending')

      get api_v1_tasks_path, params: { status: 'pending' }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(task_ids_from_response).to eq([matching_task.id])
    end

    it 'filters tasks by an exact due date' do
      matching_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-21'))
      FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-22'))

      get api_v1_tasks_path, params: { date: '2026-05-21' }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(task_ids_from_response).to eq([matching_task.id])
    end

    it 'filters tasks by a due date range' do
      inside_range_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-20'))
      second_inside_range_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-21'))
      FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-24'))

      get(
        api_v1_tasks_path,
        params: { date_from: '2026-05-20', date_to: '2026-05-21' },
        headers: headers
      )

      expect(response).to have_http_status(:ok)
      expect(task_ids_from_response).to eq([inside_range_task.id, second_inside_range_task.id])
    end
  end

  describe 'GET /api/v1/tasks/:id' do
    it 'returns the current user task' do
      task = FactoryBot.create(:task, user: user)

      get api_v1_task_path(task), headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body.dig('task', 'id')).to eq(task.id)
      expect(json_body.dig('task', 'title')).to eq(task.title)
      expect(json_body.dig('task', 'status')).to eq(task.status)
    end

    it 'returns not found for another user task' do
      task = FactoryBot.create(:task)

      get api_v1_task_path(task), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end
  end

  describe 'POST /api/v1/tasks' do
    let(:another_user) { FactoryBot.create(:user) }

    it 'creates a task for the current user' do
      expect do
        post(
          api_v1_tasks_path,
          params: {
            task: {
              user_id: another_user.id,
              title: 'Prepare report',
              description: 'Quarterly planning',
              due_date: '2026-05-25',
              status: 'pending'
            }
          },
          headers: headers,
          as: :json
        )
      end.to change(Task, :count).by(1)

      created_task = Task.order(:id).last

      expect(response).to have_http_status(:created)
      expect(created_task.user_id).to eq(user.id)
      expect(created_task.title).to eq('Prepare report')
      expect(json_body.dig('task', 'id')).to eq(created_task.id)
      expect(json_body.dig('task', 'status')).to eq('pending')
    end

    it 'creates a recurring task for the current user' do
      expect do
        post(
          api_v1_tasks_path,
          params: {
            task: {
              title: 'Daily ward round',
              description: 'Check assigned patients',
              due_date: '2026-05-25',
              status: 'planned',
              recurrence_type: 'daily',
              recurrence_config: { interval: 2 },
              recurrence_starts_on: '2026-05-25',
              recurrence_ends_on: '2026-06-25'
            }
          },
          headers: headers,
          as: :json
        )
      end.to change(Task, :count).by(1)

      created_task = Task.order(:id).last

      expect(response).to have_http_status(:created)
      expect(created_task.recurrence_type).to eq('daily')
      expect(created_task.recurrence_config).to eq('interval' => 2)
      expect(created_task.recurrence_starts_on).to eq(Date.iso8601('2026-05-25'))
      expect(created_task.recurrence_ends_on).to eq(Date.iso8601('2026-06-25'))
      expect(json_body.dig('task', 'recurrence_type')).to eq('daily')
      expect(json_body.dig('task', 'recurrence_config')).to eq('interval' => 2)
      expect(json_body.dig('task', 'recurring')).to be(true)
    end

    it 'returns validation errors for invalid attributes' do
      post(
        api_v1_tasks_path,
        params: {
          task: {
            title: '',
            description: 'Broken payload',
            due_date: '2026-05-25',
            status: 'pending'
          }
        },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq('errors' => { 'title' => ["can't be blank"] })
    end

    it 'returns validation errors for invalid recurrence attributes' do
      post(
        api_v1_tasks_path,
        params: {
          task: {
            title: 'Broken recurrence',
            description: 'Invalid recurrence payload',
            due_date: '2026-05-25',
            status: 'planned',
            recurrence_type: 'daily',
            recurrence_config: { interval: 0 }
          }
        },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq('errors' => { 'recurrence_config' => ['interval must be a positive integer'] })
    end
  end

  describe 'PATCH /api/v1/tasks/:id' do
    it 'updates the current user task' do
      task = FactoryBot.create(:task, user: user, title: 'Old title', status: 'planned')

      patch(
        api_v1_task_path(task),
        params: {
          task: {
            title: 'New title',
            description: task.description,
            due_date: task.due_date.iso8601,
            status: 'done'
          }
        },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:ok)
      expect(task.reload.title).to eq('New title')
      expect(task.status).to eq('done')
      expect(json_body.dig('task', 'title')).to eq('New title')
    end

    it 'updates recurrence attributes for the current user task' do
      task = FactoryBot.create(:task, user: user)

      patch(
        api_v1_task_path(task),
        params: {
          task: {
            recurrence_type: 'monthly_day',
            recurrence_config: { day: 15 },
            recurrence_starts_on: '2026-05-15',
            recurrence_ends_on: '2026-08-15'
          }
        },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:ok)
      expect(task.reload.recurrence_type).to eq('monthly_day')
      expect(task.recurrence_config).to eq('day' => 15)
      expect(json_body.dig('task', 'recurrence_type')).to eq('monthly_day')
      expect(json_body.dig('task', 'recurring')).to be(true)
    end

    it 'returns not found when updating another user task' do
      task = FactoryBot.create(:task)

      patch(
        api_v1_task_path(task),
        params: { task: { title: 'Updated title' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end

    it 'returns validation errors for invalid updates' do
      task = FactoryBot.create(:task, user: user, status: 'pending')

      patch(
        api_v1_task_path(task),
        params: {
          task: {
            title: task.title,
            description: task.description,
            due_date: task.due_date.iso8601,
            status: 'archived'
          }
        },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(task.reload.status).to eq('pending')
      expect(json_body).to eq('errors' => { 'status' => ['is not included in the list'] })
    end
  end

  describe 'DELETE /api/v1/tasks/:id' do
    it 'deletes the current user task' do
      task = FactoryBot.create(:task, user: user)

      expect do
        delete api_v1_task_path(task), headers: headers, as: :json
      end.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end

    it 'returns not found when deleting another user task' do
      task = FactoryBot.create(:task)

      expect do
        delete api_v1_task_path(task), headers: headers, as: :json
      end.not_to change(Task, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end
  end

  def json_body
    JSON.parse(response.body)
  end

  def task_ids_from_response
    json_body.fetch('tasks').map { |task| task.fetch('id') }
  end
end

require 'rails_helper'

RSpec.describe 'Api::V1::TaskOccurrences', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:headers) { auth_headers(user) }
  let(:json_headers) { { 'Accept' => 'application/json' } }

  describe 'PATCH /api/v1/tasks/:task_id/occurrences/:date' do
    it 'returns unauthorized without a token' do
      task = recurring_task

      patch(
        api_v1_task_task_occurrence_path(task, '2026-05-21'),
        params: { task_occurrence: { status: 'done' } },
        headers: json_headers,
        as: :json
      )

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a status override for the current user recurring task occurrence' do
      task = recurring_task

      expect do
        patch(
          api_v1_task_task_occurrence_path(task, '2026-05-21'),
          params: { task_occurrence: { status: 'done' } },
          headers: headers,
          as: :json
        )
      end.to change(TaskOccurrence, :count).by(1)

      task_occurrence = TaskOccurrence.order(:id).last

      expect(response).to have_http_status(:ok)
      expect(task_occurrence).to have_attributes(
        task_id: task.id,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'done'
      )
      expect(json_body.fetch('task')).to include(
        'id' => task.id,
        'task_id' => task.id,
        'occurrence_date' => '2026-05-21',
        'status' => 'done',
        'recurring' => true
      )
    end

    it 'updates an existing status override for the current user recurring task occurrence' do
      task = recurring_task
      task_occurrence = FactoryBot.create(
        :task_occurrence,
        task: task,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'pending'
      )

      expect do
        patch(
          api_v1_task_task_occurrence_path(task, '2026-05-21'),
          params: { task_occurrence: { status: 'cancelled' } },
          headers: headers,
          as: :json
        )
      end.not_to change(TaskOccurrence, :count)

      expect(response).to have_http_status(:ok)
      expect(task_occurrence.reload.status).to eq('cancelled')
      expect(json_body.dig('task', 'status')).to eq('cancelled')
      expect(json_body.dig('task', 'occurrence_date')).to eq('2026-05-21')
    end

    it 'returns not found for another user task occurrence' do
      task = recurring_task(user: FactoryBot.create(:user))

      patch(
        api_v1_task_task_occurrence_path(task, '2026-05-21'),
        params: { task_occurrence: { status: 'done' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => [ 'Resource not found' ] })
    end

    it 'returns bad request for an unsupported status' do
      task = recurring_task

      patch(
        api_v1_task_task_occurrence_path(task, '2026-05-21'),
        params: { task_occurrence: { status: 'archived' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:bad_request)
      expect(json_body).to eq('errors' => { 'base' => [ 'status is not included in the list' ] })
    end

    it 'returns bad request for an invalid occurrence date' do
      task = recurring_task

      patch(
        api_v1_task_task_occurrence_path(task, 'broken-date'),
        params: { task_occurrence: { status: 'done' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:bad_request)
      expect(json_body).to eq('errors' => { 'base' => [ 'occurrence_date must be a valid ISO8601 date' ] })
    end

    it 'returns bad request for a non-recurring task' do
      task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-21'))

      patch(
        api_v1_task_task_occurrence_path(task, '2026-05-21'),
        params: { task_occurrence: { status: 'done' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:bad_request)
      expect(json_body).to eq('errors' => { 'base' => [ 'task is not recurring' ] })
    end

    it 'returns bad request when the recurring task does not occur on the requested date' do
      task = recurring_task(
        recurrence_config: { 'interval' => 2 },
        recurrence_starts_on: Date.iso8601('2026-05-20')
      )

      patch(
        api_v1_task_task_occurrence_path(task, '2026-05-21'),
        params: { task_occurrence: { status: 'done' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:bad_request)
      expect(json_body).to eq('errors' => { 'base' => [ 'task does not occur on this date' ] })
    end
  end

  def json_body
    JSON.parse(response.body)
  end

  def recurring_task(attributes = {})
    defaults = {
      user: user,
      status: 'planned',
      due_date: Date.iso8601('2026-05-20'),
      recurrence_config: { 'interval' => 1 },
      recurrence_starts_on: Date.iso8601('2026-05-20'),
      recurrence_ends_on: Date.iso8601('2026-05-22')
    }

    FactoryBot.create(:task, :daily, **defaults.merge(attributes))
  end
end

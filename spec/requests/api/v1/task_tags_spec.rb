require 'rails_helper'

RSpec.describe 'Api::V1::TaskTags', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:headers) { auth_headers(user) }
  let(:json_headers) { { 'Accept' => 'application/json' } }

  describe 'POST /api/v1/tasks/:task_id/tags' do
    it 'returns unauthorized without a token' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag)

      post api_v1_task_task_tags_path(task), params: { tag: { id: tag.id } }, headers: json_headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'adds a current user tag to the current user task' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: user, name: 'Discharge')

      expect do
        post(
          api_v1_task_task_tags_path(task),
          params: { tag: { id: tag.id } },
          headers: headers,
          as: :json
        )
      end.to change(TaskTag, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(task.reload.tags).to contain_exactly(tag)
      expect(tag_ids_from_task_response).to eq([tag.id])
    end

    it 'adds a system tag to the current user task' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: nil, system: true, name: 'operations')

      expect do
        post(
          api_v1_task_task_tags_path(task),
          params: { tag: { id: tag.id } },
          headers: headers,
          as: :json
        )
      end.to change(TaskTag, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(task.reload.tags).to contain_exactly(tag)
      expect(tag_ids_from_task_response).to eq([tag.id])
    end

    it 'does not duplicate an existing task tag' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: user, name: 'Reports')
      FactoryBot.create(:task_tag, task: task, tag: tag)

      expect do
        post(
          api_v1_task_task_tags_path(task),
          params: { tag: { id: tag.id } },
          headers: headers,
          as: :json
        )
      end.not_to change(TaskTag, :count)

      expect(response).to have_http_status(:ok)
      expect(tag_ids_from_task_response).to eq([tag.id])
    end

    it 'returns not found for another user task' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag, user: user, name: 'Appointments')

      expect do
        post(
          api_v1_task_task_tags_path(task),
          params: { tag: { id: tag.id } },
          headers: headers,
          as: :json
        )
      end.not_to change(TaskTag, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end

    it 'returns not found for another user tag' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, name: 'Other user tag')

      expect do
        post(
          api_v1_task_task_tags_path(task),
          params: { tag: { id: tag.id } },
          headers: headers,
          as: :json
        )
      end.not_to change(TaskTag, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end
  end

  describe 'DELETE /api/v1/tasks/:task_id/tags/:tag_id' do
    it 'removes a tag from the current user task' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: user, name: 'Rounds')
      FactoryBot.create(:task_tag, task: task, tag: tag)

      expect do
        delete api_v1_task_task_tag_path(task, tag), headers: headers, as: :json
      end.to change(TaskTag, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
      expect(task.reload.tags).to be_empty
    end

    it 'removes a system tag from the current user task' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: nil, system: true, name: 'call')
      FactoryBot.create(:task_tag, task: task, tag: tag)

      expect do
        delete api_v1_task_task_tag_path(task, tag), headers: headers, as: :json
      end.to change(TaskTag, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(Tag.exists?(tag.id)).to be(true)
    end

    it 'returns unauthorized without a token' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: user, name: 'Calls')
      FactoryBot.create(:task_tag, task: task, tag: tag)

      delete api_v1_task_task_tag_path(task, tag), headers: json_headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for another user task' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag, user: user, name: 'Planning')

      expect do
        delete api_v1_task_task_tag_path(task, tag), headers: headers, as: :json
      end.not_to change(TaskTag, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end

    it 'returns not found for another user tag' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, name: 'Other user tag')

      expect do
        delete api_v1_task_task_tag_path(task, tag), headers: headers, as: :json
      end.not_to change(TaskTag, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end

    it 'returns not found when the tag is not attached to the task' do
      task = FactoryBot.create(:task, user: user)
      tag = FactoryBot.create(:tag, user: user, name: 'Not attached')

      expect do
        delete api_v1_task_task_tag_path(task, tag), headers: headers, as: :json
      end.not_to change(TaskTag, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end
  end

  def json_body
    JSON.parse(response.body)
  end

  def tag_ids_from_task_response
    json_body.fetch('task').fetch('tags').map { |tag| tag.fetch('id') }
  end
end

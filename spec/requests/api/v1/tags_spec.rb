require 'rails_helper'

RSpec.describe 'Api::V1::Tags', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:headers) { auth_headers(user) }
  let(:json_headers) { { 'Accept' => 'application/json' } }

  describe 'GET /api/v1/tags' do
    it 'returns unauthorized without a token' do
      get api_v1_tags_path, headers: json_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns system tags and current user tags ordered by system and name' do
      first_system_tag = FactoryBot.create(:tag, user: nil, system: true, name: 'call')
      second_system_tag = FactoryBot.create(:tag, user: nil, system: true, name: 'reporting')
      first_user_tag = FactoryBot.create(:tag, user: user, name: 'Administration')
      second_user_tag = FactoryBot.create(:tag, user: user, name: 'Rounds')
      other_user_tag = FactoryBot.create(:tag, name: 'Other user tag')

      get api_v1_tags_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(tag_ids_from_response).to eq(
        [
          first_system_tag.id,
          second_system_tag.id,
          first_user_tag.id,
          second_user_tag.id
        ]
      )
      expect(tag_ids_from_response).not_to include(other_user_tag.id)
    end
  end

  describe 'GET /api/v1/tags/:id' do
    it 'returns the current user tag' do
      tag = FactoryBot.create(:tag, user: user, name: 'Appointments')

      get api_v1_tag_path(tag), headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body.dig('tag', 'id')).to eq(tag.id)
      expect(json_body.dig('tag', 'name')).to eq('Appointments')
      expect(json_body.dig('tag', 'system')).to be(false)
    end

    it 'returns a system tag' do
      tag = FactoryBot.create(:tag, user: nil, system: true, name: 'operations')

      get api_v1_tag_path(tag), headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body.dig('tag', 'id')).to eq(tag.id)
      expect(json_body.dig('tag', 'system')).to be(true)
    end

    it 'returns not found for another user tag' do
      tag = FactoryBot.create(:tag)

      get api_v1_tag_path(tag), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end
  end

  describe 'POST /api/v1/tags' do
    it 'creates a tag for the current user' do
      expect do
        post(
          api_v1_tags_path,
          params: { tag: { name: 'Discharge planning' } },
          headers: headers,
          as: :json
        )
      end.to change(Tag, :count).by(1)

      created_tag = Tag.order(:id).last

      expect(response).to have_http_status(:created)
      expect(created_tag.user_id).to eq(user.id)
      expect(created_tag.name).to eq('Discharge planning')
      expect(created_tag.system).to be(false)
      expect(json_body.dig('tag', 'id')).to eq(created_tag.id)
      expect(json_body.dig('tag', 'name')).to eq('Discharge planning')
    end

    it 'returns validation errors for invalid attributes' do
      post(
        api_v1_tags_path,
        params: { tag: { name: '' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq('errors' => { 'name' => ["can't be blank"] })
    end

    it 'returns validation errors for a duplicate user tag name' do
      FactoryBot.create(:tag, user: user, name: 'Reports')

      post(
        api_v1_tags_path,
        params: { tag: { name: 'reports' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq('errors' => { 'name' => ['has already been taken'] })
    end
  end

  describe 'PATCH /api/v1/tags/:id' do
    it 'updates the current user tag' do
      tag = FactoryBot.create(:tag, user: user, name: 'Old tag')

      patch(
        api_v1_tag_path(tag),
        params: { tag: { name: 'Updated tag' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:ok)
      expect(tag.reload.name).to eq('Updated tag')
      expect(json_body.dig('tag', 'name')).to eq('Updated tag')
    end

    it 'returns not found when updating another user tag' do
      tag = FactoryBot.create(:tag)

      patch(
        api_v1_tag_path(tag),
        params: { tag: { name: 'Updated tag' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end

    it 'does not update a system tag' do
      tag = FactoryBot.create(:tag, user: nil, system: true, name: 'reporting')

      patch(
        api_v1_tag_path(tag),
        params: { tag: { name: 'Updated tag' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(tag.reload.name).to eq('reporting')
      expect(json_body).to eq('errors' => { 'base' => ['System tag cannot be changed'] })
    end

    it 'returns validation errors for invalid updates' do
      tag = FactoryBot.create(:tag, user: user, name: 'Tag')

      patch(
        api_v1_tag_path(tag),
        params: { tag: { name: '' } },
        headers: headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(tag.reload.name).to eq('Tag')
      expect(json_body).to eq('errors' => { 'name' => ["can't be blank"] })
    end
  end

  describe 'DELETE /api/v1/tags/:id' do
    it 'deletes the current user tag' do
      tag = FactoryBot.create(:tag, user: user)

      expect do
        delete api_v1_tag_path(tag), headers: headers, as: :json
      end.to change(Tag, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end

    it 'returns not found when deleting another user tag' do
      tag = FactoryBot.create(:tag)

      expect do
        delete api_v1_tag_path(tag), headers: headers, as: :json
      end.not_to change(Tag, :count)

      expect(response).to have_http_status(:not_found)
      expect(json_body).to eq('errors' => { 'base' => ['Resource not found'] })
    end

    it 'does not delete a system tag' do
      tag = FactoryBot.create(:tag, user: nil, system: true, name: 'call')

      expect do
        delete api_v1_tag_path(tag), headers: headers, as: :json
      end.not_to change(Tag, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq('errors' => { 'base' => ['System tag cannot be deleted'] })
    end
  end

  def json_body
    JSON.parse(response.body)
  end

  def tag_ids_from_response
    json_body.fetch('tags').map { |tag| tag.fetch('id') }
  end
end

require 'rails_helper'

RSpec.describe 'Api::V1::Users authentication', type: :request do
  let(:json_headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  describe 'POST /api/v1/users' do
    it 'creates a user and returns a jwt token' do
      expect do
        post(
          '/api/v1/users',
          params: {
            user: {
              email: 'new_user@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          },
          headers: json_headers,
          as: :json
        )
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_body.dig('user', 'email')).to eq('new_user@example.com')
    end

    it 'returns validation errors for invalid params' do
      post(
        '/api/v1/users',
        params: {
          user: {
            email: 'broken',
            password: 'short',
            password_confirmation: 'mismatch'
          }
        },
        headers: json_headers,
        as: :json
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.fetch('errors')).to include('email', 'password_confirmation')
    end
  end

  describe 'POST /api/v1/users/sign_in' do
    let!(:user) { FactoryBot.create(:user, email: 'member@example.com', password: 'password123') }

    it 'returns a jwt token for valid credentials' do
      post(
        '/api/v1/users/sign_in',
        params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        },
        headers: json_headers,
        as: :json
      )

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_body.dig('user', 'id')).to eq(user.id)
    end

    it 'returns unauthorized for invalid credentials' do
      post(
        '/api/v1/users/sign_in',
        params: {
          user: {
            email: user.email,
            password: 'wrong-password'
          }
        },
        headers: json_headers,
        as: :json
      )

      expect(response).to have_http_status(:unauthorized)
      expect(json_body).to eq('errors' => { 'base' => [ 'Invalid email or password' ] })
    end
  end

  describe 'DELETE /api/v1/users/sign_out' do
    let!(:user) { FactoryBot.create(:user, password: 'password123') }

    it 'revokes the current jwt token' do
      post(
        '/api/v1/users/sign_in',
        params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        },
        headers: json_headers,
        as: :json
      )

      token = response.headers['Authorization']

      delete '/api/v1/users/sign_out', headers: json_headers.merge('Authorization' => token)

      expect(response).to have_http_status(:ok)
      expect(json_body).to eq('message' => 'Signed out successfully')

      get '/api/v1/tasks', headers: json_headers.merge('Authorization' => token)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  def json_body
    JSON.parse(response.body)
  end
end

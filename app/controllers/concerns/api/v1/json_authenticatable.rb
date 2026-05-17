module Api::V1::JsonAuthenticatable
  private

  def render_auth_errors(record)
    render json: { errors: record.errors.to_hash }, status: :unprocessable_content
  end

  def render_invalid_credentials
    render json: { errors: { base: ['Invalid email or password'] } }, status: :unauthorized
  end

  def serialized_user(user)
    {
      id: user.id,
      email: user.email,
      created_at: user.created_at&.iso8601,
      updated_at: user.updated_at&.iso8601
    }
  end

  def set_authorization_header(user)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    response.set_header('Authorization', "Bearer #{token}")
  end
end

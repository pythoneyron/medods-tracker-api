class Api::V1::Users::SessionsController < Api::V1::BaseController
  include  Api::V1::JsonAuthenticatable

  before_action :authenticate_user!, only: :destroy

  def create
    user = User.find_for_database_authentication(email: sign_in_params[:email].to_s.downcase)

    return render_invalid_credentials unless user&.valid_password?(sign_in_params[:password])

    set_authorization_header(user)
    render json: { user: serialized_user(user) }, status: :ok
  end

  def destroy
    revoke_token!

    render json: { message: 'Signed out successfully' }, status: :ok
  end

  private

  def sign_in_params
    params.expect(user: %i[email password])
  end

  def revoke_token!
    payload = Warden::JWTAuth::TokenDecoder.new.call(raw_token)

    JwtDenylist.find_or_create_by!(jti: payload['jti']) do |denylisted_token|
      denylisted_token.exp = Time.zone.at(payload['exp'])
    end
  end

  def raw_token
    request.authorization.to_s.split.last
  end
end

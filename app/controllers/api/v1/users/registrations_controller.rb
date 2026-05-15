class Api::V1::Users::RegistrationsController < ApplicationController
  include JsonAuthenticatable

  def create
    user = User.new(sign_up_params)

    if user.save
      set_authorization_header(user)
      render json: { user: serialized_user(user) }, status: :created
    else
      render_auth_errors(user)
    end
  end

  private

  def sign_up_params
    params.expect(user: %i[email password password_confirmation])
  end
end

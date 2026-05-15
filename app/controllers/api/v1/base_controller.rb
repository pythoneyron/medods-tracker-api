class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found
    render(
      'api/v1/shared/errors',
      formats: :json,
      status: :not_found,
      locals: { errors: { base: ['Resource not found'] } }
    )
  end
end

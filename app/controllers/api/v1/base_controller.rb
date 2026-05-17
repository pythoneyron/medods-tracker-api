class Api::V1::BaseController < ApplicationController
  include Api::V1::Paginatable

  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_bad_request(errors)
    render(
      'api/v1/shared/errors',
      formats: :json,
      status: :bad_request,
      locals: { errors: errors }
    )
  end

  def render_not_found
    render(
      'api/v1/shared/errors',
      formats: :json,
      status: :not_found,
      locals: { errors: { base: ['Resource not found'] } }
    )
  end

  def render_errors(record)
    render(
      'api/v1/shared/errors',
      formats: :json,
      status: :unprocessable_content,
      locals: { errors: record.errors.to_hash }
    )
  end

  def render_message_error(message)
    render(
      'api/v1/shared/errors',
      formats: :json,
      status: :unprocessable_content,
      locals: { errors: { base: [message] } }
    )
  end
end

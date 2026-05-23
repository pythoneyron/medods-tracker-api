# frozen_string_literal: true

Devise.setup do |config|
  require "devise/orm/active_record"

  # Email authentication
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  # API/JWT mode: do not store users in session after params authentication.
  config.skip_session_storage = [ :http_auth, :params_auth ]

  # Password hashing
  config.stretches = Rails.env.test? ? 1 : 12

  # Validatable
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # API should not behave like a browser app with redirects.
  config.navigational_formats = []

  # DELETE /api/v1/users/sign_out
  config.sign_out_via = :delete

  # Devise response statuses
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # JWT
  config.jwt do |jwt|
    jwt.secret = Rails.application.secret_key_base

    # one day for test
    jwt.expiration_time = 1.day.to_i
    jwt.request_formats = { user: [ :json ] }
  end
end

module AuthHelpers
  def auth_headers(user)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    {
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end
end

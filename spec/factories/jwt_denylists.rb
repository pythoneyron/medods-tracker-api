FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2026-05-14 18:25:28" }
  end
end

class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  has_many :tasks, dependent: :destroy
  has_many :tags, dependent: :destroy
end

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'devise configuration' do
    it 'enables the expected devise modules' do
      expect(described_class.devise_modules).to include(
        :database_authenticatable,
        :registerable,
        :validatable,
        :jwt_authenticatable
      )
    end
  end

  describe 'validations' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:user)).to be_valid
    end

    it 'requires an email' do
      user = FactoryBot.build(:user, email: nil)

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'requires a password' do
      user = FactoryBot.build(:user, password: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'validates case-insensitive email uniqueness' do
      FactoryBot.create(:user, email: 'member@example.com')
      duplicate_user = FactoryBot.build(:user, email: 'MEMBER@example.com')

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'destroys dependent tasks when the user is destroyed' do
      user = FactoryBot.create(:user)
      FactoryBot.create_list(:task, 2, user: user)

      expect { user.destroy }.to change(Task, :count).by(-2)
    end
  end
end

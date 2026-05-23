require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'validations' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:tag)).to be_valid
    end

    it 'has a valid system trait' do
      expect(FactoryBot.build(:tag, :system)).to be_valid
    end

    it 'normalizes tag name whitespace before validation' do
      tag = FactoryBot.build(:tag, name: '  Rounds  ')

      expect(tag).to be_valid
      expect(tag.name).to eq('Rounds')
    end

    it 'requires system tag name to be allowed' do
      tag = FactoryBot.build(:tag, user: nil, system: true, name: 'custom')

      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include('is not included in the list')
    end

    it 'requires user for non-system tags' do
      tag = FactoryBot.build(:tag, user: nil, system: false)

      expect(tag).not_to be_valid
      expect(tag.errors[:user]).to include("can't be blank")
    end

    it 'requires system tags to be global' do
      tag = FactoryBot.build(:tag, user: FactoryBot.build(:user), system: true, name: 'call')

      expect(tag).not_to be_valid
      expect(tag.errors[:user]).to include('must be blank')
    end

    it 'validates case-insensitive user tag name uniqueness' do
      user = FactoryBot.create(:user)
      FactoryBot.create(:tag, user: user, name: 'Reports')

      duplicate_tag = FactoryBot.build(:tag, user: user, name: ' reports ')

      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors[:name]).to include('has already been taken')
    end
  end

  describe 'callbacks' do
    it 'does not allow system tags to be changed' do
      tag = FactoryBot.create(:tag, :system, name: 'operations')

      expect(tag.update(name: 'call')).to be(false)
      expect(tag.errors[:base]).to include('System tag cannot be changed')
      expect(tag.reload.name).to eq('operations')
    end

    it 'does not allow system tags to be deleted' do
      tag = FactoryBot.create(:tag, :system, name: 'reporting')

      expect(tag.destroy).to be(false)
      expect(tag.errors[:base]).to include('System tag cannot be deleted')
      expect(Tag.exists?(tag.id)).to be(true)
    end
  end
end

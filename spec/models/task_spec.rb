require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'constants' do
    it 'defines the supported statuses' do
      expect(described_class::STATUSES).to eq(%w[new pending in_progress done cancelled])
    end
  end

  describe 'validations' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:task)).to be_valid
    end

    it 'requires a user' do
      task = FactoryBot.build(:task, user: nil)

      expect(task).not_to be_valid
      expect(task.errors[:user]).to include('must exist')
    end

    it 'requires a title' do
      task = FactoryBot.build(:task, title: nil)

      expect(task).not_to be_valid
      expect(task.errors[:title]).to include("can't be blank")
    end

    it 'allows a blank description' do
      task = FactoryBot.build(:task, description: '')

      expect(task).to be_valid
    end

    it 'requires a due date' do
      task = FactoryBot.build(:task, due_date: nil)

      expect(task).not_to be_valid
      expect(task.errors[:due_date]).to include("can't be blank")
    end

    it 'requires a status' do
      task = FactoryBot.build(:task, status: nil)

      expect(task).not_to be_valid
      expect(task.errors[:status]).to include("can't be blank")
    end

    it 'accepts each supported status' do
      described_class::STATUSES.each do |status|
        task = FactoryBot.build(:task, status: status)

        expect(task).to be_valid
      end
    end

    it 'rejects a status outside the allowed list' do
      task = FactoryBot.build(:task, status: 'archived')

      expect(task).not_to be_valid
      expect(task.errors[:status]).to include('is not included in the list')
    end
  end
end

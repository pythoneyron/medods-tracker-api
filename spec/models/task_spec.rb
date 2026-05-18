require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'constants' do
    it 'defines the supported statuses' do
      expect(described_class::STATUSES).to eq(%w[planned pending in_progress done cancelled])
    end

    it 'defines the supported recurrence types' do
      expect(described_class::RECURRENCE_TYPES).to eq(
        %w[none daily monthly_day specific_dates even_days odd_days]
      )
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

    it 'requires a recurrence type' do
      task = FactoryBot.build(:task, recurrence_type: nil)

      expect(task).to be_valid
      expect(task.recurrence_type).to eq('none')
    end

    it 'rejects a recurrence type outside the allowed list' do
      task = FactoryBot.build(:task, recurrence_type: 'weekly')

      expect(task).not_to be_valid
      expect(task.errors[:recurrence_type]).to include('is not included in the list')
    end

    it 'requires recurrence config to be an object' do
      task = FactoryBot.build(:task, recurrence_config: [])

      expect(task).not_to be_valid
      expect(task.errors[:recurrence_config]).to include('must be an object')
    end

    it 'sets recurrence starts on from due date for recurring tasks' do
      task = FactoryBot.build(:task, :daily, due_date: Date.iso8601('2026-05-20'), recurrence_starts_on: nil)

      expect(task).to be_valid
      expect(task.recurrence_starts_on).to eq(Date.iso8601('2026-05-20'))
    end

    it 'rejects recurrence end date before recurrence start date' do
      task = FactoryBot.build(
        :task,
        :daily,
        recurrence_starts_on: Date.iso8601('2026-05-20'),
        recurrence_ends_on: Date.iso8601('2026-05-19')
      )

      expect(task).not_to be_valid
      expect(task.errors[:recurrence_ends_on]).to include('must be greater than or equal to recurrence_starts_on')
    end

    it 'requires a positive interval for daily recurrence' do
      task = FactoryBot.build(:task, :daily, recurrence_config: { 'interval' => 0 })

      expect(task).not_to be_valid
      expect(task.errors[:recurrence_config]).to include('interval must be a positive integer')
    end

    it 'requires a valid day for monthly day recurrence' do
      task = FactoryBot.build(:task, :monthly_day, recurrence_config: { 'day' => 32 })

      expect(task).not_to be_valid
      expect(task.errors[:recurrence_config]).to include('day must be an integer between 1 and 31')
    end

    it 'requires dates for specific dates recurrence' do
      task = FactoryBot.build(:task, :specific_dates, recurrence_config: { 'dates' => [] })

      expect(task).not_to be_valid
      expect(task.errors[:recurrence_config]).to include('dates must be a non-empty array')
    end
  end
end

require 'rails_helper'

RSpec.describe TaskOccurrence, type: :model do
  describe 'constants' do
    it 'defines the supported statuses' do
      expect(described_class::STATUSES).to eq(%w[planned pending in_progress done cancelled])
    end
  end

  describe 'validations' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:task_occurrence)).to be_valid
    end

    it 'requires a task' do
      occurrence = FactoryBot.build(:task_occurrence, task: nil)

      expect(occurrence).not_to be_valid
      expect(occurrence.errors[:task]).to include('must exist')
    end

    it 'requires an occurrence date' do
      occurrence = FactoryBot.build(:task_occurrence, occurrence_date: nil)

      expect(occurrence).not_to be_valid
      expect(occurrence.errors[:occurrence_date]).to include("can't be blank")
    end

    it 'requires a status' do
      occurrence = FactoryBot.build(:task_occurrence, status: nil)

      expect(occurrence).not_to be_valid
      expect(occurrence.errors[:status]).to include("can't be blank")
    end

    it 'accepts each supported status' do
      described_class::STATUSES.each do |status|
        occurrence = FactoryBot.build(:task_occurrence, status: status)

        expect(occurrence).to be_valid
      end
    end

    it 'rejects a status outside the allowed list' do
      occurrence = FactoryBot.build(:task_occurrence, status: 'archived')

      expect(occurrence).not_to be_valid
      expect(occurrence.errors[:status]).to include('is not included in the list')
    end

    it 'requires a unique occurrence date per task' do
      task = FactoryBot.create(:task)
      occurrence_date = Date.iso8601('2026-05-20')
      FactoryBot.create(:task_occurrence, task: task, occurrence_date: occurrence_date)

      duplicate_occurrence = FactoryBot.build(:task_occurrence, task: task, occurrence_date: occurrence_date)

      expect(duplicate_occurrence).not_to be_valid
      expect(duplicate_occurrence.errors[:occurrence_date]).to include('already exists for this task')
    end
  end
end

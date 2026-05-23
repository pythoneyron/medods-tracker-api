require 'rails_helper'

RSpec.describe Tasks::IndexQuery do
  include ActiveSupport::Testing::TimeHelpers

  describe '.call' do
    let(:user) { FactoryBot.create(:user) }

    it 'returns current user non-recurring tasks inside the requested date range' do
      other_task = FactoryBot.create(:task, due_date: Date.iso8601('2026-05-20'))
      second_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-20'))
      first_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-19'))
      FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-25'))

      result = described_class.call(
        user: user,
        params: { date_from: '2026-05-19', date_to: '2026-05-20' }
      )

      expect(result).to be_success
      expect(result.date_from).to eq(Date.iso8601('2026-05-19'))
      expect(result.date_to).to eq(Date.iso8601('2026-05-20'))
      expect(result.items.map(&:task_id)).to eq([first_task.id, second_task.id])
      expect(result.items.map(&:task_id)).not_to include(other_task.id)
      expect(result.items.map(&:occurrence_date)).to eq(
        [
          Date.iso8601('2026-05-19'),
          Date.iso8601('2026-05-20')
        ]
      )
    end

    it 'returns generated recurring task occurrences inside the requested date range' do
      task = FactoryBot.create(
        :task,
        :daily,
        user: user,
        recurrence_config: { 'interval' => 2 },
        recurrence_starts_on: Date.iso8601('2026-05-20'),
        recurrence_ends_on: Date.iso8601('2026-05-25')
      )

      result = described_class.call(
        user: user,
        params: { date_from: '2026-05-20', date_to: '2026-05-25' }
      )

      expect(result).to be_success
      expect(result.items.map(&:task_id)).to eq([task.id, task.id, task.id])
      expect(result.items.map(&:occurrence_date)).to eq(
        [
          Date.iso8601('2026-05-20'),
          Date.iso8601('2026-05-22'),
          Date.iso8601('2026-05-24')
        ]
      )
    end

    it 'uses task occurrence status overrides before filtering by status' do
      task = FactoryBot.create(
        :task,
        :daily,
        user: user,
        status: 'planned',
        recurrence_config: { 'interval' => 1 },
        recurrence_starts_on: Date.iso8601('2026-05-20'),
        recurrence_ends_on: Date.iso8601('2026-05-22')
      )
      FactoryBot.create(
        :task_occurrence,
        task: task,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'done'
      )

      result = described_class.call(
        user: user,
        params: { status: 'done', date_from: '2026-05-20', date_to: '2026-05-22' }
      )

      expect(result).to be_success
      expect(result.items.size).to eq(1)
      expect(result.items.first).to have_attributes(
        task_id: task.id,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'done'
      )
    end

    it 'returns errors for an unsupported status filter' do
      FactoryBot.create(:task, user: user, status: 'planned', due_date: Date.iso8601('2026-05-21'))

      result = described_class.call(
        user: user,
        params: { status: 'archived', date: '2026-05-21' }
      )

      expect(result).not_to be_success
      expect(result.errors).to eq(['status is not included in the list'])
      expect(result.items).to eq([])
      expect(result.date_from).to be_nil
      expect(result.date_to).to be_nil
    end

    it 'uses today and the default window when date params are omitted' do
      travel_to(Time.zone.parse('2026-05-21 10:00:00')) do
        inside_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-06-20'))
        FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-06-21'))

        result = described_class.call(user: user, params: {})

        expect(result).to be_success
        expect(result.date_from).to eq(Date.iso8601('2026-05-21'))
        expect(result.date_to).to eq(Date.iso8601('2026-06-20'))
        expect(result.items.map(&:task_id)).to eq([inside_task.id])
      end
    end

    it 'uses the exact date when date is provided' do
      matching_task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-21'))
      FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-22'))

      result = described_class.call(user: user, params: { date: '2026-05-21' })

      expect(result).to be_success
      expect(result.date_from).to eq(Date.iso8601('2026-05-21'))
      expect(result.date_to).to eq(Date.iso8601('2026-05-21'))
      expect(result.items.map(&:task_id)).to eq([matching_task.id])
    end

    it 'returns errors for an invalid date' do
      result = described_class.call(user: user, params: { date: 'broken-date' })

      expect(result).not_to be_success
      expect(result.errors).to eq(['date must be a valid ISO8601 date'])
      expect(result.items).to eq([])
    end

    it 'returns errors when date range is inverted' do
      result = described_class.call(
        user: user,
        params: { date_from: '2026-05-22', date_to: '2026-05-21' }
      )

      expect(result).not_to be_success
      expect(result.errors).to eq(['date_to must be greater than or equal to date_from'])
      expect(result.items).to eq([])
    end

    it 'returns errors when date range is too large' do
      result = described_class.call(
        user: user,
        params: { date_from: '2026-01-01', date_to: '2027-01-03' }
      )

      expect(result).not_to be_success
      expect(result.errors).to eq(['date range cannot be greater than 366 days'])
      expect(result.items).to eq([])
    end
  end
end

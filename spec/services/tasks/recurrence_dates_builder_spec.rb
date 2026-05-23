require 'rails_helper'

RSpec.describe Tasks::RecurrenceDatesBuilder do
  describe '.call' do
    it 'returns an empty array for non-recurring tasks' do
      task = FactoryBot.build(:task, recurrence_type: 'none')

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-10')
      )

      expect(result).to eq([])
    end

    it 'returns an empty array for recurring tasks without recurrence start date' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'daily',
        recurrence_config: { 'interval' => 1 },
        recurrence_starts_on: nil
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-10')
      )

      expect(result).to eq([])
    end

    it 'returns an empty array for invalid requested window' do
      task = FactoryBot.build(
        :task,
        :daily,
        recurrence_starts_on: Date.iso8601('2026-05-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-10'),
        date_to: Date.iso8601('2026-05-01')
      )

      expect(result).to eq([])
    end

    it 'returns daily recurrence dates with integer interval' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'daily',
        recurrence_config: { 'interval' => 2 },
        recurrence_starts_on: Date.iso8601('2026-05-10')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-10'),
        date_to: Date.iso8601('2026-05-16')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-10'),
          Date.iso8601('2026-05-12'),
          Date.iso8601('2026-05-14'),
          Date.iso8601('2026-05-16')
        ]
      )
    end

    it 'returns daily recurrence dates with string interval' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'daily',
        recurrence_config: { 'interval' => '2' },
        recurrence_starts_on: Date.iso8601('2026-05-10')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-10'),
        date_to: Date.iso8601('2026-05-14')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-10'),
          Date.iso8601('2026-05-12'),
          Date.iso8601('2026-05-14')
        ]
      )
    end

    it 'calculates daily recurrence from the original recurrence start date' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'daily',
        recurrence_config: { 'interval' => 3 },
        recurrence_starts_on: Date.iso8601('2026-05-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-10'),
        date_to: Date.iso8601('2026-05-20')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-10'),
          Date.iso8601('2026-05-13'),
          Date.iso8601('2026-05-16'),
          Date.iso8601('2026-05-19')
        ]
      )
    end

    it 'does not return daily recurrence dates outside recurrence boundaries' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'daily',
        recurrence_config: { 'interval' => 1 },
        recurrence_starts_on: Date.iso8601('2026-05-10'),
        recurrence_ends_on: Date.iso8601('2026-05-12')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-20')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-10'),
          Date.iso8601('2026-05-11'),
          Date.iso8601('2026-05-12')
        ]
      )
    end

    it 'returns monthly recurrence dates for configured day' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'monthly_day',
        recurrence_config: { 'day' => 15 },
        recurrence_starts_on: Date.iso8601('2026-05-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-07-31')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-15'),
          Date.iso8601('2026-06-15'),
          Date.iso8601('2026-07-15')
        ]
      )
    end

    it 'skips months without configured monthly day' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'monthly_day',
        recurrence_config: { 'day' => 31 },
        recurrence_starts_on: Date.iso8601('2026-01-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-01-01'),
        date_to: Date.iso8601('2026-04-30')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-01-31'),
          Date.iso8601('2026-03-31')
        ]
      )
    end

    it 'does not return monthly recurrence dates outside recurrence boundaries' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'monthly_day',
        recurrence_config: { 'day' => 15 },
        recurrence_starts_on: Date.iso8601('2026-05-16'),
        recurrence_ends_on: Date.iso8601('2026-07-14')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-07-31')
      )

      expect(result).to eq([Date.iso8601('2026-06-15')])
    end

    it 'returns unique sorted specific dates inside effective window' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'specific_dates',
        recurrence_config: {
          'dates' => [
            '2026-05-17',
            '2026-05-10',
            '2026-05-10',
            '2026-06-01'
          ]
        },
        recurrence_starts_on: Date.iso8601('2026-05-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-31')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-10'),
          Date.iso8601('2026-05-17')
        ]
      )
    end

    it 'does not return specific dates outside recurrence boundaries' do
      task = FactoryBot.build(
        :task,
        recurrence_type: 'specific_dates',
        recurrence_config: {
          'dates' => %w[
            2026-05-10
            2026-05-17
            2026-05-24
          ]
        },
        recurrence_starts_on: Date.iso8601('2026-05-11'),
        recurrence_ends_on: Date.iso8601('2026-05-20')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-31')
      )

      expect(result).to eq([Date.iso8601('2026-05-17')])
    end

    it 'returns even days of month' do
      task = FactoryBot.build(
        :task,
        :even_days,
        recurrence_starts_on: Date.iso8601('2026-05-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-06')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-02'),
          Date.iso8601('2026-05-04'),
          Date.iso8601('2026-05-06')
        ]
      )
    end

    it 'returns odd days of month' do
      task = FactoryBot.build(
        :task,
        :odd_days,
        recurrence_starts_on: Date.iso8601('2026-05-01')
      )

      result = described_class.call(
        task: task,
        date_from: Date.iso8601('2026-05-01'),
        date_to: Date.iso8601('2026-05-06')
      )

      expect(result).to eq(
        [
          Date.iso8601('2026-05-01'),
          Date.iso8601('2026-05-03'),
          Date.iso8601('2026-05-05')
        ]
      )
    end
  end
end

require 'rails_helper'

RSpec.describe Tasks::OccurrenceStatusUpdater do
  describe '.call' do
    let(:user) { FactoryBot.create(:user) }

    it 'creates a task occurrence status override for a recurring task date' do
      task = recurring_task
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: '2026-05-21',
          status: 'done'
        )
      end.to change(TaskOccurrence, :count).by(1)

      task_occurrence = TaskOccurrence.order(:id).last

      expect(result).to be_success
      expect(task_occurrence).to have_attributes(
        task_id: task.id,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'done'
      )
      expect(result.item).to have_attributes(
        task_id: task.id,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'done',
        task_occurrence: task_occurrence
      )
    end

    it 'updates an existing task occurrence status override' do
      task = recurring_task
      task_occurrence = FactoryBot.create(
        :task_occurrence,
        task: task,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'pending'
      )
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: '2026-05-21',
          status: 'done'
        )
      end.not_to change(TaskOccurrence, :count)

      expect(result).to be_success
      expect(task_occurrence.reload.status).to eq('done')
      expect(result.item).to have_attributes(
        task_id: task.id,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'done',
        task_occurrence: task_occurrence
      )
    end

    it 'returns errors for an unsupported status' do
      task = recurring_task
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: '2026-05-21',
          status: 'archived'
        )
      end.not_to change(TaskOccurrence, :count)

      expect(result).not_to be_success
      expect(result.item).to be_nil
      expect(result.errors).to eq([ 'status is not included in the list' ])
    end

    it 'returns errors for an invalid occurrence date' do
      task = recurring_task
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: 'broken-date',
          status: 'done'
        )
      end.not_to change(TaskOccurrence, :count)

      expect(result).not_to be_success
      expect(result.item).to be_nil
      expect(result.errors).to eq([ 'occurrence_date must be a valid ISO8601 date' ])
    end

    it 'returns errors when the task does not belong to the user' do
      task = recurring_task(user: FactoryBot.create(:user))
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: '2026-05-21',
          status: 'done'
        )
      end.not_to change(TaskOccurrence, :count)

      expect(result).not_to be_success
      expect(result.item).to be_nil
      expect(result.errors).to eq([ 'task not found' ])
    end

    it 'returns errors for a non-recurring task' do
      task = FactoryBot.create(:task, user: user, due_date: Date.iso8601('2026-05-21'))
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: '2026-05-21',
          status: 'done'
        )
      end.not_to change(TaskOccurrence, :count)

      expect(result).not_to be_success
      expect(result.item).to be_nil
      expect(result.errors).to eq([ 'task is not recurring' ])
    end

    it 'returns errors when the recurring task does not occur on the requested date' do
      task = recurring_task(
        recurrence_config: { 'interval' => 2 },
        recurrence_starts_on: Date.iso8601('2026-05-20')
      )
      result = nil

      expect do
        result = described_class.call(
          user: user,
          task_id: task.id,
          occurrence_date: '2026-05-21',
          status: 'done'
        )
      end.not_to change(TaskOccurrence, :count)

      expect(result).not_to be_success
      expect(result.item).to be_nil
      expect(result.errors).to eq([ 'task does not occur on this date' ])
    end

    def recurring_task(attributes = {})
      defaults = {
        user: user,
        status: 'planned',
        due_date: Date.iso8601('2026-05-20'),
        recurrence_config: { 'interval' => 1 },
        recurrence_starts_on: Date.iso8601('2026-05-20'),
        recurrence_ends_on: Date.iso8601('2026-05-22')
      }

      FactoryBot.create(:task, :daily, **defaults.merge(attributes))
    end
  end
end

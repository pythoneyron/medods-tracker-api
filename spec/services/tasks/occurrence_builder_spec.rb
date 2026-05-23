require 'rails_helper'

RSpec.describe Tasks::OccurrenceBuilder do
  include ActiveSupport::Testing::TimeHelpers

  describe '.call' do
    it 'builds an occurrence item with task attributes and task status' do
      task = FactoryBot.create(:task, status: 'planned', due_date: Date.iso8601('2026-05-21'))

      item = described_class.call(task: task, occurrence_date: Date.iso8601('2026-05-21'))

      expect(item).to have_attributes(
        task: task,
        task_id: task.id,
        occurrence_date: Date.iso8601('2026-05-21'),
        status: 'planned',
        task_occurrence: nil,
        title: task.title,
        description: task.description,
        due_date: task.due_date,
        recurrence_type: task.recurrence_type,
        recurrence_config: task.recurrence_config,
        recurrence_starts_on: task.recurrence_starts_on,
        recurrence_ends_on: task.recurrence_ends_on,
        tags: task.tags
      )
    end

    it 'uses task occurrence status when an occurrence override exists' do
      task = FactoryBot.create(:task, status: 'planned')
      task_occurrence = FactoryBot.create(
        :task_occurrence,
        task: task,
        occurrence_date: Date.iso8601('2026-05-22'),
        status: 'done'
      )

      item = described_class.call(
        task: task,
        occurrence_date: Date.iso8601('2026-05-22'),
        task_occurrence: task_occurrence
      )

      expect(item.status).to eq('done')
      expect(item.task_occurrence).to eq(task_occurrence)
    end

    it 'uses task occurrence updated_at when an occurrence override exists' do
      task = FactoryBot.create(:task)

      travel_to(Time.zone.parse('2026-05-21 10:00:00')) do
        task.update!(title: 'Updated task')
      end

      task_occurrence = nil
      travel_to(Time.zone.parse('2026-05-22 10:00:00')) do
        task_occurrence = FactoryBot.create(
          :task_occurrence,
          task: task,
          occurrence_date: Date.iso8601('2026-05-23'),
          status: 'done'
        )
      end

      item = described_class.call(
        task: task.reload,
        occurrence_date: Date.iso8601('2026-05-23'),
        task_occurrence: task_occurrence
      )

      expect(item.updated_at.to_i).to eq(task_occurrence.updated_at.to_i)
      expect(item.updated_at.to_i).not_to eq(task.updated_at.to_i)
    end
  end
end

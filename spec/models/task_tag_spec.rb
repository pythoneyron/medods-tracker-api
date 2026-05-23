require 'rails_helper'

RSpec.describe TaskTag, type: :model do
  describe 'validations' do
    it 'has a valid factory' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag, user: task.user)

      expect(FactoryBot.build(:task_tag, task: task, tag: tag)).to be_valid
    end

    it 'allows system tags for any task user' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag, user: nil, system: true, name: 'call')

      expect(FactoryBot.build(:task_tag, task: task, tag: tag)).to be_valid
    end

    it 'rejects tags owned by another user' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag)

      task_tag = FactoryBot.build(:task_tag, task: task, tag: tag)

      expect(task_tag).not_to be_valid
      expect(task_tag.errors[:tag]).to include('is not available for this task')
    end

    it 'requires a unique tag per task' do
      task = FactoryBot.create(:task)
      tag = FactoryBot.create(:tag, user: task.user)
      FactoryBot.create(:task_tag, task: task, tag: tag)

      duplicate_task_tag = FactoryBot.build(:task_tag, task: task, tag: tag)

      expect(duplicate_task_tag).not_to be_valid
      expect(duplicate_task_tag.errors[:tag_id]).to include('already assigned to this task')
    end
  end
end

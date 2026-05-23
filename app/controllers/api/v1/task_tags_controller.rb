class Api::V1::TaskTagsController < Api::V1::BaseController
  before_action :set_task

  def create
    tag = available_tags.find(create_tag_id)

    @task_tag = @task.task_tags.find_or_initialize_by(tag: tag)
    was_new_record = @task_tag.new_record?

    @task_tag.save!

    @task = @task.reload

    render(
      "api/v1/tasks/show",
      formats: :json,
      status: was_new_record ? :created : :ok
    )
  end

  def destroy
    tag = available_tags.find(params[:tag_id])
    task_tag = @task.task_tags.find_by!(tag: tag)

    task_tag.destroy!

    head :no_content
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:task_id])
  end

  def available_tags
    Tag.available_for(current_user)
  end

  def create_tag_id
    params.expect(tag: %i[ id ])[:id]
  end
end

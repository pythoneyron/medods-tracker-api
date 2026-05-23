class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: %i[ show update destroy ]

  def index
    result = Tasks::IndexQuery.call(user: current_user, params: filter_params)

    return render_bad_request(base: result.errors) unless result.success?

    @task_items = paginate_collection(result.items)
    @date_from = result.date_from
    @date_to = result.date_to

    render :index, status: :ok
  end

  def show
    render :show, status: :ok
  end

  def create
    @task = current_user.tasks.new(task_params)

    return render :show, status: :created if @task.save

    render_errors(@task)
  end

  def update
    return render :show, status: :ok if @task.update(task_params)

    render_errors(@task)
  end

  def destroy
    @task.destroy!

    head :no_content
  end

  private

  def set_task
    @task = current_user.tasks.find(params.expect(:id))
  end

  def task_params
    params.expect(
      task: [
        :title,
        :description,
        :due_date,
        :status,
        :recurrence_type,
        :recurrence_starts_on,
        :recurrence_ends_on,
        { recurrence_config: {} }
      ]
    )
  end

  def filter_params
    params.permit(:status, :date, :date_from, :date_to)
  end
end

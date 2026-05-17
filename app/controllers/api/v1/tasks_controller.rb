class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: %i[ show update destroy ]

  def index
    @tasks = paginate_collection(filtered_tasks)

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
    params.expect(task: %i[ title description due_date status ])
  end

  def filter_params
    params.permit(:status, :date, :date_from, :date_to)
  end

  def filtered_tasks
    tasks = current_user.tasks.includes(:tags).order(due_date: :asc, created_at: :asc, id: :asc)

    tasks = tasks.where(status: filter_params[:status]) if filter_params[:status].present?

    if filter_params[:date].present?
      tasks = tasks.where(due_date: filter_params[:date])
    elsif filter_params[:date_from].present? && filter_params[:date_to].present?
      tasks = tasks.where(due_date: filter_params[:date_from]..filter_params[:date_to])
    end

    tasks
  end
end

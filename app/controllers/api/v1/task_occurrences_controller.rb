class Api::V1::TaskOccurrencesController < Api::V1::BaseController
  def update
    result = Tasks::OccurrenceStatusUpdater.call(
      user: current_user,
      task_id: params.expect(:task_id),
      occurrence_date: params.expect(:date),
      status: task_occurrence_params[:status]
    )

    if result.success?
      @task_item = result.item

      return render :show, status: :ok
    end

    render_result_errors(result)
  end

  private

  def task_occurrence_params
    params.expect(task_occurrence: [ :status ])
  end

  def render_result_errors(result)
    return render_not_found if result.errors.include?("task not found")

    render_bad_request(base: result.errors)
  end
end

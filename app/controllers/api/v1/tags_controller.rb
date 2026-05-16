class Api::V1::TagsController < Api::V1::BaseController
  before_action :set_tag, only: %i[ show update destroy ]

  def index
    @tags = Tag.available_for(current_user).order(system: :desc, name: :asc)

    render :index, status: :ok
  end

  def show
    render :show, status: :ok
  end

  def create
    @tag = current_user.tags.new(tag_params)

    return render :show, status: :created if @tag.save

    render_errors(@tag)
  end

  def update
    return render_message_error('System tag cannot be changed') if @tag.system?

    return render :show, status: :ok if @tag.update(tag_params)

    render_errors(@tag)
  end

  def destroy
    return render_message_error('System tag cannot be deleted') if @tag.system?

    @tag.destroy!

    head :no_content
  end

  private

  def set_tag
    @tag = Tag.available_for(current_user).find(params.expect(:id))
  end

  def tag_params
    params.expect(tag: %i[ name ])
  end
end

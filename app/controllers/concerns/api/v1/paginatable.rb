# frozen_string_literal: true

module Api::V1::Paginatable
  extend ActiveSupport::Concern

  class InvalidPaginationParams < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('Invalid pagination parameters')
    end
  end

  included do
    include Pagy::Method

    rescue_from InvalidPaginationParams, with: :render_pagination_errors
    rescue_from Pagy::OptionError, with: :render_pagy_option_error
  end

  private

  def paginate_collection(collection, paginator: :offset, **options)
    @pagy, records = pagy(
      paginator,
      collection,
      **pagination_options.merge(options)
    )

    @pagination = pagination_payload(@pagy)

    records
  end

  def pagination_options
    {
      jsonapi: true,
      page_key: 'number',
      limit_key: 'size',
      page: pagination_page_number,
      limit: pagination_page_size
    }
  end

  def pagination_page_number
    positive_integer(params.dig(:page, :number), 'page.number') || 1
  end

  def pagination_page_size
    value = positive_integer(params.dig(:page, :size), 'page.size') || pagination_default_limit

    return value if value <= pagination_max_limit

    raise InvalidPaginationParams, 'page.size' => ["must be less than or equal to #{pagination_max_limit}"]
  end

  def pagination_default_limit
    Pagy::OPTIONS.fetch(:limit)
  end

  def pagination_max_limit
    Pagy::OPTIONS.fetch(:max_limit)
  end

  def positive_integer(value, field)
    return if value.blank?

    integer = Integer(value, 10)

    return integer if integer.positive?

    raise InvalidPaginationParams, field => ['must be greater than or equal to 1']
  rescue ArgumentError, TypeError
    raise InvalidPaginationParams, field => ['must be an integer']
  end

  def pagination_payload(pagy)
    data = pagy.data_hash(
      data_keys: %i[
        page limit count pages previous next from to
        current_url first_url previous_url next_url last_url
      ]
    )

    {
      meta: {
        pagination: {
          current_page: data[:page],
          page_size: data[:limit],
          total_count: data[:count],
          total_pages: data[:pages],
          previous_page: data[:previous],
          next_page: data[:next],
          from: data[:from],
          to: data[:to]
        }
      },
      links: {
        self: data[:current_url],
        first: data[:first_url],
        prev: data[:previous_url],
        next: data[:next_url],
        last: data[:last_url]
      }
    }
  end

  def render_pagination_errors(error)
    render_bad_request(error.errors)
  end

  def render_pagy_option_error(error)
    render_bad_request('page' => ["invalid pagination option #{error.option}"])
  end
end

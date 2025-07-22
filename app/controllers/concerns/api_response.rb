module ApiResponse
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
  end

  private

  def render_success(data, status: :ok)
    render json: {
      success: true,
      data: data
    }, status: status
  end

  def render_error(message, status: :unprocessable_entity)
    render json: {
      success: false,
      error: message
    }, status: status
  end

  def render_errors(errors, status: :unprocessable_entity)
    render json: {
      success: false,
      errors: errors
    }, status: status
  end

  def not_found(exception)
    render_error("Resource not found", status: :not_found)
  end

  def unprocessable_entity(exception)
    render_errors(exception.record.errors.full_messages, status: :unprocessable_entity)
  end

  def bad_request(exception)
    render_error("Bad request", status: :bad_request)
  end
end

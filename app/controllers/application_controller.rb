class ApplicationController < ActionController::API
  before_action :authenticate_api_key!

  private

  def authenticate_api_key!
    api_key = request.headers["Nemery-Api-Key"]
    unless api_key && ENV["API_SECRET_KEY"] && ActiveSupport::SecurityUtils.secure_compare(api_key, ENV["API_SECRET_KEY"])
      render json: {error: "Unauthorized"}, status: :unauthorized
    end
  end
end

# NOTE: to test remote API: curl -i -H "Nemery-Api-Key: API_SECRET_KEY" https://nemery-api-0db43f6e1ac2.herokuapp.com/users

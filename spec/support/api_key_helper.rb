module ApiKeyRequestHelper
  def api_key_headers(extra_headers = {})
    { 'Nemery-Api-Key' => ENV['API_SECRET_KEY'] || 'test-api-key' }.merge(extra_headers)
  end
end

RSpec.configure do |config|
  config.include ApiKeyRequestHelper, type: :request
end 
json.extract! user, :id, :name, :email, :device, :created_at, :updated_at
json.url user_url(user, format: :json)

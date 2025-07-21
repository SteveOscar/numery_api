class SearchUsersTool < ApplicationTool
    tool_name "search_users"
    description "Searches for users by name or ID"

    arguments do
    optional(:user_ids).array(:integer).description("IDs of users")
    optional(:query).maybe(:string).description("Search query")
    end

    def call(user_ids: nil, query: nil)
    users = User.all
    if user_ids.present?
        users = users.where(id: user_ids)
    end
    if query.present?
        users = users.where("name LIKE :query", query: "%#{query}%")
    end
    users.limit(20).to_json(only: [:id, :name, :email])
    end
end

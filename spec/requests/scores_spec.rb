require "rails_helper"

RSpec.describe "Scores API", type: :request do
  let(:valid_user_attributes) do
    {
      name: "steve",
      email: "fake@email.com",
      device: 1243
    }
  end

  let(:valid_user_attributes2) do
    {
      name: "carl",
      email: "fake@email2.com",
      device: 2375
    }
  end

  describe "GET /scores/:device" do
    it "pulls the high scores" do
      user1 = User.create!(valid_user_attributes)
      user2 = User.create!(valid_user_attributes2)
      user1.scores.create!(score: 22)
      user2.scores.create!(score: 10)
      user2.scores.create!(score: 32)
      user1.scores.create!(score: 9)
      user1.scores.create!(score: 82)

      get "/scores/#{user1.device}", headers: api_key_headers
      puts response.body
      result = JSON.parse(response.body)
      high_scores = result["data"]["high_scores"]
      expect(high_scores.length).to eq(5)
      expect(high_scores.first["score"]).to eq(82)
    end

    it "handles non-existent device" do
      get "/scores/nonexistent_device", headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      expect(result["data"]["high_scores"]).to be_empty
    end

    it "handles device with no scores" do
      user = User.create!(valid_user_attributes)
      get "/scores/#{user.device}", headers: api_key_headers
      result = JSON.parse(response.body)
      high_scores = result["data"]["high_scores"]
      expect(high_scores).to be_empty
    end

    it "handles device with single score" do
      user = User.create!(valid_user_attributes)
      user.scores.create!(score: 100)
      get "/scores/#{user.device}", headers: api_key_headers
      result = JSON.parse(response.body)
      high_scores = result["data"]["high_scores"]
      expect(high_scores.length).to eq(1)
      expect(high_scores.first["score"]).to eq(100)
    end

    it "handles special characters in device" do
      special_device = "device@123#$%"
      user = User.create!(valid_user_attributes.merge(device: special_device))
      user.scores.create!(score: 100)
      get "/scores/#{CGI.escape(special_device)}", headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      expect(result["data"]["high_scores"].first["score"]).to eq(100)
    end

    it "handles very long device string" do
      long_device = "a" * 500
      user = User.create!(valid_user_attributes.merge(device: long_device))
      user.scores.create!(score: 100)
      get "/scores/#{long_device}", headers: api_key_headers
      expect(response).to have_http_status(:success)
    end

    it "requires API key" do
      user = User.create!(valid_user_attributes)
      get "/scores/#{user.device}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "handles invalid API key" do
      user = User.create!(valid_user_attributes)
      get "/scores/#{user.device}", headers: { "X-API-KEY" => "invalid_key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns scores sorted by highest first" do
      user = User.create!(valid_user_attributes)
      user.scores.create!(score: 100)
      user.scores.create!(score: 300)
      user.scores.create!(score: 200)
      get "/scores/#{user.device}", headers: api_key_headers
      result = JSON.parse(response.body)
      scores = result["data"]["high_scores"].map { |s| s["score"] }
      expect(scores).to eq([300, 200, 100])
    end

    it "handles duplicate scores" do
      user = User.create!(valid_user_attributes)
      3.times { user.scores.create!(score: 100) }
      get "/scores/#{user.device}", headers: api_key_headers
      result = JSON.parse(response.body)
      high_scores = result["data"]["high_scores"]
      expect(high_scores.length).to eq(3)
      expect(high_scores.map { |s| s["score"] }).to all(eq(100))
    end
  end

  describe "POST /scores/new/:device/" do
    it "creates a high score" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 99 },
                                          headers: api_key_headers
      puts response.body
      result = JSON.parse(response.body)
      score = result["data"]["data"]["attributes"]["score"]
      expect(score).to eq(99)
    end

    it "handles non-existent device" do
      post "/scores/new/nonexistent_device/", params: { user: 999, device: "nonexistent_device", score: 100 },
                                              headers: api_key_headers
      expect(response).to have_http_status(:not_found)
    end

    it "handles non-existent user" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: 999, device: user.device, score: 100 },
                                          headers: api_key_headers
      expect(response).to have_http_status(:not_found)
    end

    it "rejects negative scores" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: -10 },
                                          headers: api_key_headers
      expect(response).to have_http_status(:unprocessable_entity)
      result = JSON.parse(response.body)
      expect(result["errors"]).to include("Score must be greater than 0")
    end

    it "rejects zero scores" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 0 },
                                          headers: api_key_headers
      expect(response).to have_http_status(:unprocessable_entity)
      result = JSON.parse(response.body)
      expect(result["errors"]).to include("Score must be greater than 0")
    end

    it "handles missing score parameter" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device }, headers: api_key_headers
      expect(response).to have_http_status(:unprocessable_entity)
      result = JSON.parse(response.body)
      expect(result["errors"]).to include("Score can't be blank")
    end

    it "handles missing user parameter" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { device: user.device, score: 100 }, headers: api_key_headers
      expect(response).to have_http_status(:not_found)
    end

    it "handles missing device parameter" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, score: 100 }, headers: api_key_headers
      expect(response).to have_http_status(:success)
    end

    it "accepts string numeric scores" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: "100" },
                                          headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      score = result["data"]["data"]["attributes"]["score"]
      expect(score).to eq(100)
    end

    it "rejects non-numeric scores" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: "abc" },
                                          headers: api_key_headers
      expect(response).to have_http_status(:unprocessable_entity)
      result = JSON.parse(response.body)
      expect(result["errors"]).to include("Score is not a number")
    end

    it "handles very large scores" do
      user = User.create!(valid_user_attributes)
      large_score = 2147483647
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: large_score },
                                          headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      score = result["data"]["data"]["attributes"]["score"]
      expect(score).to eq(large_score)
    end

    it "handles decimal scores by truncating" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 100.7 },
                                          headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      score = result["data"]["data"]["attributes"]["score"]
      expect(score).to eq(100)
    end

    it "requires API key" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 100 }
      expect(response).to have_http_status(:unauthorized)
    end

    it "handles invalid API key" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 100 },
                                          headers: { "X-API-KEY" => "invalid_key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "handles mismatched device parameters" do
      user1 = User.create!(valid_user_attributes)
      user2 = User.create!(valid_user_attributes2)
      post "/scores/new/#{user1.device}/", params: { user: user1.id, device: user2.device, score: 100 },
                                           headers: api_key_headers
      expect(response).to have_http_status(:success)
    end

    it "handles special characters in device URL" do
      special_device = "device@123#$%"
      user = User.create!(valid_user_attributes.merge(device: special_device))
      post "/scores/new/#{CGI.escape(special_device)}/", params: { user: user.id, device: special_device, score: 100 },
                                                         headers: api_key_headers
      expect(response).to have_http_status(:success)
    end

    it "increments score count for user" do
      user = User.create!(valid_user_attributes)
      expect {
        post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 100 },
                                            headers: api_key_headers
      }.to change { user.scores.count }.by(1)
    end

    it "handles concurrent score submissions" do
      user = User.create!(valid_user_attributes)
      threads = []
      5.times do |i|
        threads << Thread.new do
          post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 100 + i },
                                              headers: api_key_headers
        end
      end
      threads.each(&:join)
      expect(user.scores.count).to eq(5)
    end
  end
end

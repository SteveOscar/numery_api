require 'rails_helper'

RSpec.describe "Scores API", type: :request do
  let(:valid_user_attributes) do
    {
      name: 'steve',
      email: 'fake@email.com',
      device: 1243
    }
  end

  let(:valid_user_attributes2) do
    {
      name: 'carl',
      email: 'fake@email2.com',
      device: 2375
    }
  end

  describe "GET /high_scores" do
    it "pulls the high scores" do
      user1 = User.create!(valid_user_attributes)
      user2 = User.create!(valid_user_attributes2)
      user1.scores.create!(score: 22)
      user2.scores.create!(score: 10)
      user2.scores.create!(score: 32)
      user1.scores.create!(score: 9)
      user1.scores.create!(score: 82)

      get "/high_scores"
      result = JSON.parse(response.body)
      expect(result.length).to eq(5)
      expect(result.last['score']).to eq(82)
    end
  end

  describe "POST /scores" do
    it "creates a high score" do
      user = User.create!(valid_user_attributes)
      post "/scores", params: { user_id: user.id, device: user.device, score: 99 }
      result = JSON.parse(response.body)
      expect(result['score']).to eq(99)
    end
  end
end 
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

  describe "GET /scores/:device" do
    it "pulls the high scores" do
      user1 = User.create!(valid_user_attributes)
      user2 = User.create!(valid_user_attributes2)
      user1.scores.create!(score: 22)
      user2.scores.create!(score: 10)
      user2.scores.create!(score: 32)
      user1.scores.create!(score: 9)
      user1.scores.create!(score: 82)

      get "/scores/#{user1.device}"
      puts response.body
      result = JSON.parse(response.body)
      expect(result['high_scores'].length).to eq(5)
      expect(result['high_scores'].first.last).to eq(82)
    end
  end

  describe "POST /scores/new/:device/" do
    it "creates a high score" do
      user = User.create!(valid_user_attributes)
      post "/scores/new/#{user.device}/", params: { user: user.id, device: user.device, score: 99 }
      puts response.body
      result = JSON.parse(response.body)
      expect(result['score']).to eq(99)
    end
  end
end 
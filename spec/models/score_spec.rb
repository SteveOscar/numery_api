# == Schema Information
#
# Table name: scores
#
#  id         :integer          not null, primary key
#  score      :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe Score, type: :model do
  let(:user) { User.create!(name: "Test User", device: "device123") }
  let(:valid_attributes) { { score: 100, user: user } }

  describe "associations" do
    it "belongs to user" do
      score = Score.new(valid_attributes)
      expect(score.user).to eq(user)
    end

    it "requires a user" do
      score = Score.new(valid_attributes.except(:user))
      expect(score).not_to be_valid
      expect(score.errors[:user]).to include("must exist")
    end

    it "is destroyed when user is destroyed" do
      score = Score.create!(valid_attributes)
      expect { user.destroy }.to change(Score, :count).by(-1)
    end
  end

  describe "validations" do
    context "score validation" do
      it "is valid with valid attributes" do
        score = Score.new(valid_attributes)
        expect(score).to be_valid
      end

      it "requires a score" do
        score = Score.new(valid_attributes.except(:score))
        expect(score).not_to be_valid
        expect(score.errors[:score]).to include("can't be blank")
      end

      it "requires score to be greater than 0" do
        score = Score.new(valid_attributes.merge(score: 0))
        expect(score).not_to be_valid
        expect(score.errors[:score]).to include("must be greater than 0")
      end

      it "rejects negative scores" do
        score = Score.new(valid_attributes.merge(score: -1))
        expect(score).not_to be_valid
        expect(score.errors[:score]).to include("must be greater than 0")
      end

      it "accepts positive scores" do
        [1, 100, 999999].each do |score_value|
          score = Score.new(valid_attributes.merge(score: score_value))
          expect(score).to be_valid, "Expected score #{score_value} to be valid"
        end
      end

      it "handles very large scores" do
        large_score = 2147483647
        score = Score.new(valid_attributes.merge(score: large_score))
        expect(score).to be_valid
      end

      it "handles string numbers" do
        score = Score.new(valid_attributes.merge(score: "100"))
        expect(score).to be_valid
        expect(score.score).to eq(100)
      end

      it "rejects non-numeric strings" do
        score = Score.new(valid_attributes.merge(score: "abc"))
        expect(score).not_to be_valid
        expect(score.errors[:score]).to include("is not a number")
      end

      it "rejects nil score" do
        score = Score.new(valid_attributes.merge(score: nil))
        expect(score).not_to be_valid
        expect(score.errors[:score]).to include("can't be blank")
      end

      it "handles decimal scores by converting to integer" do
        score = Score.new(valid_attributes.merge(score: 100.7))
        expect(score).to be_valid
        expect(score.score).to eq(100)
      end
    end
  end

  describe "scopes" do
    let!(:user2) { User.create!(name: "User2", device: "device2") }
    let!(:score1) { Score.create!(score: 100, user: user) }
    let!(:score2) { Score.create!(score: 200, user: user2) }
    let!(:score3) { Score.create!(score: 150, user: user) }

    describe ".high_scores" do
      it "returns scores in descending order" do
        result = Score.high_scores
        expect(result.map(&:score)).to eq([200, 150, 100])
      end

      it "respects limit parameter" do
        expect(Score.high_scores(2).count).to eq(2)
        expect(Score.high_scores(2).first.score).to eq(200)
      end

      it "handles limit of 0" do
        expect(Score.high_scores(0)).to be_empty
      end

      it "handles limit greater than available scores" do
        expect(Score.high_scores(100).count).to eq(3)
      end

      it "handles empty table" do
        Score.destroy_all
        expect(Score.high_scores).to be_empty
      end

      it "handles ties in scores" do
        Score.create!(score: 200, user: user)
        result = Score.high_scores
        expect(result.first(2).map(&:score)).to all(eq(200))
      end
    end

    describe ".recent" do
      it "returns scores in reverse chronological order" do
        result = Score.recent
        expect(result).to eq([score3, score2, score1])
      end

      it "respects limit parameter" do
        expect(Score.recent(2).count).to eq(2)
      end

      it "handles limit of 0" do
        expect(Score.recent(0)).to be_empty
      end

      it "handles empty table" do
        Score.destroy_all
        expect(Score.recent).to be_empty
      end
    end

    describe ".by_user" do
      it "returns scores for specific user" do
        result = Score.by_user(user)
        expect(result).to contain_exactly(score1, score3)
      end

      it "returns empty for user with no scores" do
        user3 = User.create!(name: "User3", device: "device3")
        expect(Score.by_user(user3)).to be_empty
      end

      it "handles nil user" do
        expect(Score.by_user(nil)).to be_empty
      end
    end
  end

  describe "instance methods" do
    let!(:user2) { User.create!(name: "User2", device: "device2") }
    let!(:score1) { Score.create!(score: 100, user: user) }
    let!(:score2) { Score.create!(score: 200, user: user2) }
    let!(:score3) { Score.create!(score: 150, user: user) }

    describe "#rank" do
      it "calculates rank correctly" do
        expect(score1.rank).to eq(3)
        expect(score2.rank).to eq(1)
        expect(score3.rank).to eq(2)
      end

      it "handles ties" do
        tied_score = Score.create!(score: 150, user: user2)
        expect(score3.rank).to eq(2)
        expect(tied_score.rank).to eq(2)
      end

      it "handles single score" do
        Score.destroy_all
        single_score = Score.create!(score: 100, user: user)
        expect(single_score.rank).to eq(1)
      end

      it "handles lowest score" do
        low_score = Score.create!(score: 1, user: user2)
        expect(low_score.rank).to eq(4)
      end

      it "handles highest score" do
        high_score = Score.create!(score: 1000, user: user2)
        expect(high_score.rank).to eq(1)
      end
    end

    describe "#percentile" do
      it "calculates percentile correctly" do
        expect(score1.percentile).to eq(33.33)
        expect(score2.percentile).to eq(100.0)
        expect(score3.percentile).to eq(66.67)
      end

      it "handles ties" do
        tied_score = Score.create!(score: 150, user: user2)
        expect([score3.percentile, tied_score.percentile]).to all(eq(75.0))
      end

      it "handles single score" do
        Score.destroy_all
        single_score = Score.create!(score: 100, user: user)
        expect(single_score.percentile).to eq(100.0)
      end

      it "returns 100 when no scores exist" do
        Score.destroy_all
        score = Score.new(score: 100, user: user)
        expect(score.percentile).to eq(100)
      end

      it "handles lowest score" do
        low_score = Score.create!(score: 1, user: user2)
        expect(low_score.percentile).to eq(25.0)
      end

      it "handles highest score" do
        high_score = Score.create!(score: 1000, user: user2)
        expect(high_score.percentile).to eq(100.0)
      end

      it "rounds to 2 decimal places" do
        7.times { |i| Score.create!(score: 50 + i, user: user2) }
        middle_score = Score.find_by(score: 53)
        expect(middle_score.percentile).to be_a(Float)
        expect(middle_score.percentile.to_s.split('.').last.length).to be <= 2
      end
    end
  end

  describe "class methods" do
    let!(:user2) { User.create!(name: "User2", device: "device2") }
    let!(:user3) { User.create!(name: "User3", device: "device3") }

    before do
      Score.create!(score: 100, user: user)
      Score.create!(score: 200, user: user2)
      Score.create!(score: 150, user: user)
      Score.create!(score: 80, user: user3)
    end

    describe ".global_high_scores" do
      it "returns scores with users included" do
        result = Score.global_high_scores
        expect(result.first.user).to be_present
        expect(result.map(&:score)).to eq([200, 150, 100, 80])
      end

      it "respects limit parameter" do
        expect(Score.global_high_scores(2).count).to eq(2)
      end

      it "handles empty table" do
        Score.destroy_all
        expect(Score.global_high_scores).to be_empty
      end

      it "includes user data without additional queries" do
        result = Score.global_high_scores
        expect(result.first.user).to be_present
        expect(result.first.user.name).to be_present
      end
    end

    describe ".user_high_scores" do
      it "returns high scores for specific user" do
        result = Score.user_high_scores(user)
        expect(result.map(&:score)).to eq([150, 100])
      end

      it "respects limit parameter" do
        3.times { |i| Score.create!(score: 300 + i, user: user) }
        result = Score.user_high_scores(user, 3)
        expect(result.count).to eq(3)
      end

      it "handles user with no scores" do
        user4 = User.create!(name: "User4", device: "device4")
        expect(Score.user_high_scores(user4)).to be_empty
      end

      it "handles nil user" do
        expect(Score.user_high_scores(nil)).to be_empty
      end
    end

    describe ".average_score" do
      it "calculates average correctly" do
        expect(Score.average_score).to eq(132.5)
      end

      it "returns 0 for empty table" do
        Score.destroy_all
        expect(Score.average_score).to eq(0)
      end

      it "handles single score" do
        Score.destroy_all
        Score.create!(score: 100, user: user)
        expect(Score.average_score).to eq(100.0)
      end

      it "handles decimal results" do
        Score.destroy_all
        Score.create!(score: 101, user: user)
        Score.create!(score: 102, user: user2)
        expect(Score.average_score).to eq(101.5)
      end
    end

    describe ".median_score" do
      it "calculates median for odd number of scores" do
        expect(Score.median_score).to eq(125.0)
      end

      it "calculates median for even number of scores" do
        Score.create!(score: 90, user: user3)
        median = Score.median_score
        expect([90.0, 95.0, 100.0, 120.0, 125.0]).to include(median)
      end

      it "returns 0 for empty table" do
        Score.destroy_all
        expect(Score.median_score).to eq(0)
      end

      it "handles single score" do
        Score.destroy_all
        Score.create!(score: 100, user: user)
        expect(Score.median_score).to eq(100)
      end

      it "handles two scores" do
        Score.destroy_all
        Score.create!(score: 100, user: user)
        Score.create!(score: 200, user: user2)
        expect(Score.median_score).to eq(150.0)
      end

      it "handles duplicate scores" do
        Score.destroy_all
        3.times { Score.create!(score: 100, user: user) }
        expect(Score.median_score).to eq(100)
      end
    end
  end
end

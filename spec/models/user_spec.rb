# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  device     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe User, type: :model do
  let(:valid_attributes) do
    {
      name: "Test User",
      device: "device123"
    }
  end

  describe "validations" do
    context "device validation" do
      it "is valid with valid attributes" do
        user = User.new(valid_attributes)
        expect(user).to be_valid
      end

      it "requires a device" do
        user = User.new(valid_attributes.except(:device))
        expect(user).not_to be_valid
        expect(user.errors[:device]).to include("can't be blank")
      end

      it "requires unique device" do
        User.create!(valid_attributes)
        duplicate_user = User.new(valid_attributes)
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:device]).to include("has already been taken")
      end

      it "handles empty string device" do
        user = User.new(valid_attributes.merge(device: ""))
        expect(user).not_to be_valid
        expect(user.errors[:device]).to include("can't be blank")
      end

      it "handles whitespace-only device" do
        user = User.new(valid_attributes.merge(device: "   "))
        expect(user).not_to be_valid
        expect(user.errors[:device]).to include("can't be blank")
      end

      it "handles very long device string" do
        long_device = "a" * 1000
        user = User.new(valid_attributes.merge(device: long_device))
        expect(user).to be_valid
      end
    end

    context "name validation" do
      it "requires a name" do
        user = User.new(valid_attributes.except(:name))
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it "requires unique name" do
        User.create!(valid_attributes)
        duplicate_user = User.new(valid_attributes.merge(device: "different_device"))
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:name]).to include("has already been taken")
      end

      it "handles empty string name" do
        user = User.new(valid_attributes.merge(name: ""))
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it "handles whitespace-only name" do
        user = User.new(valid_attributes.merge(name: "   "))
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it "handles special characters in name" do
        special_names = ["User@123", "User#$%", "用户", "🎮Player", "User\nName"]
        special_names.each_with_index do |name, index|
          user = User.new(valid_attributes.merge(name: name, device: "device#{index}"))
          expect(user).to be_valid, "Expected #{name} to be valid"
        end
      end

      it "handles very long name" do
        long_name = "a" * 1000
        user = User.new(valid_attributes.merge(name: long_name))
        expect(user).to be_valid
      end
    end
  end

  describe "associations" do
    let(:user) { User.create!(valid_attributes) }

    it "has many scores" do
      expect(user.scores).to eq([])
    end

    it "destroys associated scores when user is destroyed" do
      score = user.scores.create!(score: 100)
      expect { user.destroy }.to change(Score, :count).by(-1)
    end

    it "handles user with no scores" do
      expect(user.scores.count).to eq(0)
    end

    it "handles user with multiple scores" do
      user.scores.create!(score: 100)
      user.scores.create!(score: 200)
      user.scores.create!(score: 150)
      expect(user.scores.count).to eq(3)
    end
  end

  describe "scopes" do
    let!(:user1) { User.create!(name: "User1", device: "device1") }
    let!(:user2) { User.create!(name: "User2", device: "device2") }
    let!(:user3) { User.create!(name: "User3", device: "device3") }

    before do
      user1.scores.create!(score: 100)
      user1.scores.create!(score: 200)
      user2.scores.create!(score: 150)
    end

    describe ".with_scores" do
      it "returns users who have scores" do
        expect(User.with_scores).to contain_exactly(user1, user2)
      end

      it "handles empty result" do
        Score.destroy_all
        expect(User.with_scores).to be_empty
      end

      it "returns unique users even with multiple scores" do
        expect(User.with_scores.count).to eq(2)
      end
    end

    describe ".top_players" do
      it "returns users ordered by highest score" do
        result = User.top_players
        expect(result.first).to eq(user1)
        expect(result.second).to eq(user2)
      end

      it "respects limit parameter" do
        result = User.top_players(1)
        expect(result.length).to eq(1)
        expect(result.first).to eq(user1)
      end

      it "handles limit of 0" do
        expect(User.top_players(0)).to be_empty
      end

      it "handles limit greater than available users" do
        result = User.top_players(100)
        expect(result.length).to eq(2)
      end

      it "handles no users with scores" do
        Score.destroy_all
        expect(User.top_players).to be_empty
      end
    end
  end

  describe "instance methods" do
    let(:user) { User.create!(valid_attributes) }

    describe "#best_score" do
      it "returns 0 when user has no scores" do
        expect(user.best_score).to eq(0)
      end

      it "returns highest score when user has scores" do
        user.scores.create!(score: 100)
        user.scores.create!(score: 200)
        user.scores.create!(score: 150)
        expect(user.best_score).to eq(200)
      end

      it "handles single score" do
        user.scores.create!(score: 100)
        expect(user.best_score).to eq(100)
      end

      it "handles negative scores" do
        expect(user.best_score).to eq(0)
      end
    end

    describe "#average_score" do
      it "returns 0 when user has no scores" do
        expect(user.average_score).to eq(0)
      end

      it "calculates average correctly" do
        user.scores.create!(score: 100)
        user.scores.create!(score: 200)
        expect(user.average_score).to eq(150.0)
      end

      it "handles single score" do
        user.scores.create!(score: 100)
        expect(user.average_score).to eq(100.0)
      end

      it "handles decimal averages" do
        user.scores.create!(score: 100)
        user.scores.create!(score: 101)
        expect(user.average_score).to eq(100.5)
      end
    end

    describe "#score_count" do
      it "returns 0 when user has no scores" do
        expect(user.score_count).to eq(0)
      end

      it "returns correct count" do
        3.times { |i| user.scores.create!(score: 100 + i) }
        expect(user.score_count).to eq(3)
      end
    end

    describe "#recent_scores" do
      it "returns empty array when user has no scores" do
        expect(user.recent_scores).to eq([])
      end

      it "returns scores in reverse chronological order" do
        old_score = user.scores.create!(score: 100)
        sleep(0.1)
        new_score = user.scores.create!(score: 200)
        expect(user.recent_scores).to eq([new_score, old_score])
      end

      it "respects limit parameter" do
        6.times { |i| user.scores.create!(score: 100 + i) }
        expect(user.recent_scores(3).count).to eq(3)
      end

      it "handles limit of 0" do
        user.scores.create!(score: 100)
        expect(user.recent_scores(0)).to be_empty
      end

      it "handles limit greater than available scores" do
        user.scores.create!(score: 100)
        expect(user.recent_scores(10).count).to eq(1)
      end
    end
  end

  describe ".find_by_device_or_create" do
    let(:device_params) { { device: "new_device", name: "New User" } }

    it "creates new user when device doesn't exist" do
      expect { User.find_by_device_or_create(device_params) }.to change(User, :count).by(1)
    end

    it "returns existing user when device exists" do
      existing_user = User.create!(name: "Existing", device: "existing_device")
      result = User.find_by_device_or_create({ device: "existing_device", name: "Different Name" })
      expect(result).to eq(existing_user)
      expect(result.name).to eq("Existing")
    end

    it "handles nil device" do
      params = { device: nil, name: "Test" }
      user = User.find_by_device_or_create(params)
      expect(user).not_to be_persisted
      expect(user.errors[:device]).to include("can't be blank")
    end

    it "handles missing name in params" do
      params = { device: "test_device" }
      user = User.find_by_device_or_create(params)
      expect(user).not_to be_persisted
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "handles empty params" do
      user = User.find_by_device_or_create({})
      expect(user).not_to be_persisted
      expect(user.errors[:device]).to include("can't be blank")
      expect(user.errors[:name]).to include("can't be blank")
    end
  end
end

require "rails_helper"

RSpec.describe "Users API", type: :request do
  let(:valid_attributes) do
    {
      name: "steve",
      # email: 'fake@email.com',
      device: 1243
    }
  end

  let(:invalid_attributes) do
    {
      # email: 'fake@email.com',
      device: 1243
    }
  end

  let(:invalid_attributes2) do
    {
      # email: 'fake@email.com',
      name: "steve"
    }
  end

  describe "GET /users" do
    it "returns all users" do
      user = User.create!(valid_attributes)
      get "/users", headers: api_key_headers
      puts response.body
      result = JSON.parse(response.body)
      user_data = result["data"]["data"].first["attributes"]
      expect(user_data["name"]).to eq(user.name)
    end
  end

  describe "GET /users/:id" do
    it "returns the requested user" do
      user = User.create!(valid_attributes)
      get "/users/#{user.device}", headers: api_key_headers
      puts response.body
      result = JSON.parse(response.body)
      user_data = result["data"]["data"]["attributes"]
      expect(user_data["name"]).to eq(user.name)
    end
  end

  describe "POST /users" do
    context "with valid params" do
      it "creates a new User" do
        expect {
          post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        }.to change(User, :count).by(1)
      end

      it "returns the newly created user" do
        post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        expect(User.first).to be_a(User)
        expect(User.first).to be_persisted
      end
    end

    context "with invalid params" do
      it "can't create with no name" do
        post "/users", params: invalid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        expect(User.first).to be(nil)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name can't be blank")
      end

      it "can't create with no device" do
        post "/users", params: invalid_attributes2.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        expect(User.first).to be(nil)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Device can't be blank")
      end

      it "can't duplicate name" do
        User.create!(valid_attributes)
        post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name has already been taken")
      end

      it "can't duplicate device" do
        User.create!(valid_attributes)
        post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Device has already been taken")
      end
    end
  end
end

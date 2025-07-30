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

    it "returns empty array when no users exist" do
      get "/users", headers: api_key_headers
      result = JSON.parse(response.body)
      expect(result["data"]["data"]).to be_empty
    end

    it "returns multiple users" do
      user1 = User.create!(valid_attributes)
      user2 = User.create!(name: "User2", device: "device2")
      get "/users", headers: api_key_headers
      result = JSON.parse(response.body)
      expect(result["data"]["data"].length).to eq(2)
    end

    it "requires API key" do
      get "/users"
      expect(response).to have_http_status(:unauthorized)
    end

    it "handles invalid API key" do
      get "/users", headers: { "X-API-KEY" => "invalid_key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "includes user attributes in response" do
      user = User.create!(valid_attributes)
      get "/users", headers: api_key_headers
      result = JSON.parse(response.body)
      user_data = result["data"]["data"].first["attributes"]
      expect(user_data).to have_key("name")
      expect(user_data).to have_key("device")
    end

    it "handles large number of users" do
      100.times { |i| User.create!(name: "User#{i}", device: "device#{i}") }
      get "/users", headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      expect(result["data"]["data"].length).to eq(100)
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

    it "returns 404 for non-existent user" do
      get "/users/nonexistent_device", headers: api_key_headers
      expect(response).to have_http_status(:not_found)
    end

    it "requires API key" do
      user = User.create!(valid_attributes)
      get "/users/#{user.device}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "handles invalid API key" do
      user = User.create!(valid_attributes)
      get "/users/#{user.device}", headers: { "X-API-KEY" => "invalid_key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "handles special characters in device" do
      special_device = "device@123#$%"
      user = User.create!(valid_attributes.merge(device: special_device))
      get "/users/#{CGI.escape(special_device)}", headers: api_key_headers
      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      user_data = result["data"]["data"]["attributes"]
      expect(user_data["name"]).to eq(user.name)
    end

    it "handles very long device string" do
      long_device = "a" * 500
      user = User.create!(valid_attributes.merge(device: long_device))
      get "/users/#{long_device}", headers: api_key_headers
      expect(response).to have_http_status(:success)
    end

    it "includes all user attributes" do
      user = User.create!(valid_attributes)
      get "/users/#{user.device}", headers: api_key_headers
      result = JSON.parse(response.body)
      user_data = result["data"]["data"]["attributes"]
      expect(user_data["name"]).to eq(user.name)
      expect(user_data["device"]).to eq(user.device)
    end

    it "handles numeric-like device strings" do
      numeric_device = "12345"
      user = User.create!(valid_attributes.merge(device: numeric_device))
      get "/users/#{numeric_device}", headers: api_key_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /users" do
    context "with valid params" do
      it "creates a new User" do
        expect {
          post "/users", params: valid_attributes.to_json,
                         headers: api_key_headers("CONTENT_TYPE" => "application/json")
        }.to change(User, :count).by(1)
      end

      it "returns the newly created user" do
        post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        expect(User.first).to be_a(User)
        expect(User.first).to be_persisted
      end

      it "handles special characters in name" do
        special_name_attrs = valid_attributes.merge(name: "User@123#$%", device: "special_device")
        post "/users", params: special_name_attrs.to_json,
                       headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:success)
        expect(User.last.name).to eq("User@123#$%")
      end

      it "handles unicode characters in name" do
        unicode_attrs = valid_attributes.merge(name: "用户🎮", device: "unicode_device")
        post "/users", params: unicode_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:success)
        expect(User.last.name).to eq("用户🎮")
      end

      it "handles very long names" do
        long_name = "a" * 1000
        long_name_attrs = valid_attributes.merge(name: long_name, device: "long_name_device")
        post "/users", params: long_name_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:success)
        expect(User.last.name).to eq(long_name)
      end

      it "handles very long device strings" do
        long_device = "a" * 1000
        long_device_attrs = valid_attributes.merge(device: long_device, name: "Long Device User")
        post "/users", params: long_device_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:success)
        expect(User.last.device).to eq(long_device)
      end

      it "returns proper JSON structure" do
        post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:success)
        result = JSON.parse(response.body)
        expect(result).to have_key("data")
      end
    end

    context "with invalid params" do
      it "can't create with no name" do
        post "/users", params: invalid_attributes.to_json,
                       headers: api_key_headers("CONTENT_TYPE" => "application/json")
        puts response.body
        expect(User.first).to be(nil)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name can't be blank")
      end

      it "can't create with no device" do
        post "/users", params: invalid_attributes2.to_json,
                       headers: api_key_headers("CONTENT_TYPE" => "application/json")
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

      it "handles empty string name" do
        empty_name_attrs = valid_attributes.merge(name: "", device: "empty_name_device")
        post "/users", params: empty_name_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name can't be blank")
      end

      it "handles whitespace-only name" do
        whitespace_name_attrs = valid_attributes.merge(name: "   ", device: "whitespace_device")
        post "/users", params: whitespace_name_attrs.to_json,
                       headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name can't be blank")
      end

      it "handles empty string device" do
        empty_device_attrs = valid_attributes.merge(device: "", name: "Empty Device User")
        post "/users", params: empty_device_attrs.to_json,
                       headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Device can't be blank")
      end

      it "handles nil values" do
        nil_attrs = { name: nil, device: nil }
        post "/users", params: nil_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name can't be blank")
        expect(result["errors"]).to include("Device can't be blank")
      end

      it "handles malformed JSON" do
        expect {
          post "/users", params: "invalid json", headers: api_key_headers("CONTENT_TYPE" => "application/json")
        }.to raise_error(JSON::ParserError)
      end

      it "handles empty JSON" do
        post "/users", params: "{}", headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        result = JSON.parse(response.body)
        expect(result["errors"]).to include("Name can't be blank")
        expect(result["errors"]).to include("Device can't be blank")
      end

      it "requires API key" do
        post "/users", params: valid_attributes.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "handles invalid API key" do
        post "/users", params: valid_attributes.to_json,
                       headers: { "CONTENT_TYPE" => "application/json", "X-API-KEY" => "invalid_key" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "handles missing content type" do
        post "/users", params: valid_attributes.to_json, headers: api_key_headers
        expect(response).to have_http_status(:success)
      end

      it "handles wrong content type" do
        post "/users", params: valid_attributes.to_json, headers: api_key_headers("CONTENT_TYPE" => "text/plain")
        expect(response).to have_http_status(:success)
      end

      it "returns proper error format" do
        post "/users", params: invalid_attributes.to_json,
                       headers: api_key_headers("CONTENT_TYPE" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        result = JSON.parse(response.body)
        expect(result).to have_key("errors")
        expect(result["errors"]).to be_an(Array)
      end

      it "handles concurrent creation attempts with same data" do
        threads = []
        results = []
        5.times do
          threads << Thread.new do
            begin
              post "/users", params: valid_attributes.to_json,
                             headers: api_key_headers("CONTENT_TYPE" => "application/json")
              results << response.status
            rescue => e
              results << e.message
            end
          end
        end
        threads.each(&:join)

        success_count = results.count(201)
        error_count = results.count(422)
        expect(success_count).to eq(1)
        expect(error_count).to eq(4)
        expect(User.count).to eq(1)
      end
    end
  end

  describe "edge cases and error handling" do
    it "handles extremely large request bodies" do
      huge_name = "a" * 100000
      huge_attrs = valid_attributes.merge(name: huge_name, device: "huge_device")
      post "/users", params: huge_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect([200, 201, 413, 422]).to include(response.status)
    end

    it "handles SQL injection attempts in name" do
      malicious_name = "'; DROP TABLE users; --"
      malicious_attrs = valid_attributes.merge(name: malicious_name, device: "malicious_device")
      post "/users", params: malicious_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.last.name).to eq(malicious_name)
      expect(User.count).to be > 0
    end

    it "handles SQL injection attempts in device" do
      malicious_device = "'; DROP TABLE users; --"
      malicious_attrs = valid_attributes.merge(device: malicious_device, name: "Malicious User")
      post "/users", params: malicious_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.last.device).to eq(malicious_device)
    end

    it "handles XSS attempts in name" do
      xss_name = "<script>alert('xss')</script>"
      xss_attrs = valid_attributes.merge(name: xss_name, device: "xss_device")
      post "/users", params: xss_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.last.name).to eq(xss_name)
    end

    it "handles null bytes in strings" do
      null_byte_name = "User\x00Test"
      null_attrs = valid_attributes.merge(name: null_byte_name, device: "null_device")
      expect {
        post "/users", params: null_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      }.to raise_error(ArgumentError, "string contains null byte")
    end

    it "handles newlines in name" do
      multiline_name = "User\nWith\nNewlines"
      multiline_attrs = valid_attributes.merge(name: multiline_name, device: "multiline_device")
      post "/users", params: multiline_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.last.name).to eq(multiline_name)
    end

    it "handles tabs and special whitespace" do
      special_name = "User\tWith\rSpecial\vWhitespace"
      special_attrs = valid_attributes.merge(name: special_name, device: "special_device")
      post "/users", params: special_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.last.name).to eq(special_name)
    end

    it "handles case sensitivity in device" do
      User.create!(name: "Test1", device: "TestDevice")
      case_attrs = valid_attributes.merge(name: "Test2", device: "testdevice")
      post "/users", params: case_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.count).to eq(2)
    end

    it "handles case sensitivity in name" do
      User.create!(name: "TestUser", device: "device1")
      case_attrs = valid_attributes.merge(name: "testuser", device: "device2")
      post "/users", params: case_attrs.to_json, headers: api_key_headers("CONTENT_TYPE" => "application/json")
      expect(response).to have_http_status(:success)
      expect(User.count).to eq(2)
    end
  end
end

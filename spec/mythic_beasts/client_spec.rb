require "spec_helper"

RSpec.describe MythicBeasts::Client do
  let(:api_key) { "test_key" }
  let(:api_secret) { "test_secret" }
  let(:client) { described_class.new(api_key: api_key, api_secret: api_secret) }
  let(:token) { "test_token_123" }

  before do
    allow_any_instance_of(MythicBeasts::Auth).to receive(:token).and_return(token)
  end

  describe "#get" do
    it "makes a GET request with bearer token" do
      stub = stub_request(:get, "https://api.mythic-beasts.com/test")
        .with(headers: {"Authorization" => "Bearer #{token}"})
        .to_return(
          status: 200,
          body: {data: "test"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = client.get("/test")

      expect(stub).to have_been_requested
      expect(result).to eq({"data" => "test"})
    end

    it "includes query parameters" do
      stub = stub_request(:get, "https://api.mythic-beasts.com/test?foo=bar")
        .with(headers: {"Authorization" => "Bearer #{token}"})
        .to_return(status: 200, body: "{}")

      client.get("/test", params: {foo: "bar"})

      expect(stub).to have_been_requested
    end
  end

  describe "#post" do
    it "makes a POST request with JSON body" do
      stub = stub_request(:post, "https://api.mythic-beasts.com/test")
        .with(
          body: {name: "test"}.to_json,
          headers: {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 201, body: {id: 1}.to_json)

      result = client.post("/test", body: {name: "test"})

      expect(stub).to have_been_requested
      expect(result).to eq({"id" => 1})
    end
  end

  describe "#put" do
    it "makes a PUT request" do
      stub = stub_request(:put, "https://api.mythic-beasts.com/test")
        .with(body: {update: true}.to_json)
        .to_return(status: 200, body: {success: true}.to_json)

      result = client.put("/test", body: {update: true})

      expect(stub).to have_been_requested
      expect(result).to eq({"success" => true})
    end
  end

  describe "#delete" do
    it "makes a DELETE request" do
      stub = stub_request(:delete, "https://api.mythic-beasts.com/test")
        .to_return(status: 204)

      client.delete("/test")

      expect(stub).to have_been_requested
    end
  end

  describe "error handling" do
    it "raises NotFoundError on 404" do
      stub_request(:get, "https://api.mythic-beasts.com/test")
        .to_return(status: 404)

      expect { client.get("/test") }.to raise_error(MythicBeasts::NotFoundError)
    end

    it "raises ValidationError on 400" do
      stub_request(:post, "https://api.mythic-beasts.com/test")
        .to_return(status: 400)

      expect { client.post("/test") }.to raise_error(MythicBeasts::ValidationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:get, "https://api.mythic-beasts.com/test")
        .to_return(status: 429)

      expect { client.get("/test") }.to raise_error(MythicBeasts::RateLimitError)
    end

    it "raises ServerError on 500" do
      stub_request(:get, "https://api.mythic-beasts.com/test")
        .to_return(status: 500)

      expect { client.get("/test") }.to raise_error(MythicBeasts::ServerError)
    end
  end

  describe "initialization" do
    it "initializes dns client" do
      expect(client.dns).to be_a(MythicBeasts::DNS)
    end

    it "initializes vps client" do
      expect(client.vps).to be_a(MythicBeasts::VPS)
    end
  end
end

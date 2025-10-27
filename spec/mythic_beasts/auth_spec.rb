require "spec_helper"

RSpec.describe MythicBeasts::Auth do
  let(:api_key) { "test_key" }
  let(:api_secret) { "test_secret" }
  let(:auth) { described_class.new(api_key: api_key, api_secret: api_secret) }

  describe "#token" do
    let(:token_response) do
      {
        "access_token" => "test_token_123",
        "expires_in" => 300,
        "token_type" => "bearer"
      }
    end

    before do
      stub_request(:post, "https://auth.mythic-beasts.com/login")
        .with(
          body: {"grant_type" => "client_credentials"},
          basic_auth: [api_key, api_secret]
        )
        .to_return(
          status: 200,
          body: token_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    it "fetches a new token" do
      token = auth.token
      expect(token).to eq("test_token_123")
    end

    it "caches the token" do
      auth.token
      auth.token

      expect(WebMock).to have_requested(:post, "https://auth.mythic-beasts.com/login").once
    end

    it "refreshes expired token" do
      auth.token

      # Fast forward time
      allow(Time).to receive(:now).and_return(Time.now + 400)

      auth.token

      expect(WebMock).to have_requested(:post, "https://auth.mythic-beasts.com/login").twice
    end

    context "when authentication fails" do
      before do
        stub_request(:post, "https://auth.mythic-beasts.com/login")
          .to_return(status: 401)
      end

      it "raises AuthenticationError" do
        expect { auth.token }.to raise_error(MythicBeasts::AuthenticationError)
      end
    end
  end
end

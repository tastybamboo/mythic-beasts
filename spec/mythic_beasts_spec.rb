require "spec_helper"

RSpec.describe MythicBeasts do
  it "has a version number" do
    expect(MythicBeasts::VERSION).not_to be nil
  end

  describe ".configure" do
    after do
      # Reset configuration after each test
      MythicBeasts.api_key = nil
      MythicBeasts.api_secret = nil
    end

    it "allows configuration via block" do
      MythicBeasts.configure do |config|
        config.api_key = "test_key"
        config.api_secret = "test_secret"
      end

      expect(MythicBeasts.api_key).to eq("test_key")
      expect(MythicBeasts.api_secret).to eq("test_secret")
    end
  end

  describe ".client" do
    before do
      MythicBeasts.configure do |config|
        config.api_key = "test_key"
        config.api_secret = "test_secret"
      end
    end

    after do
      MythicBeasts.instance_variable_set(:@client, nil)
      MythicBeasts.api_key = nil
      MythicBeasts.api_secret = nil
    end

    it "returns a client instance" do
      expect(MythicBeasts.client).to be_a(MythicBeasts::Client)
    end

    it "memoizes the client" do
      client1 = MythicBeasts.client
      client2 = MythicBeasts.client

      expect(client1).to be(client2)
    end
  end
end

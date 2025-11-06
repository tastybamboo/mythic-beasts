# frozen_string_literal: true

RSpec.describe MythicBeasts::Proxy do
  let(:client) { instance_double(MythicBeasts::Client) }
  let(:proxy) { described_class.new(client) }

  describe "#list" do
    it "fetches all proxy endpoints" do
      expect(client).to receive(:get).with("/proxy/endpoints").and_return(
        {"endpoints" => [{"domain" => "example.com"}]}
      )
      endpoints = proxy.list
      expect(endpoints).to be_an(Array)
    end
  end

  describe "#list_for_domain" do
    it "fetches endpoints for a specific domain" do
      expect(client).to receive(:get).with("/proxy/endpoints/example.com").and_return(
        {"endpoints" => []}
      )
      proxy.list_for_domain("example.com")
    end
  end

  describe "#list_for_hostname" do
    it "fetches endpoints for a specific hostname" do
      expect(client).to receive(:get).with("/proxy/endpoints/example.com/www").and_return(
        {"endpoints" => []}
      )
      proxy.list_for_hostname("example.com", "www")
    end
  end

  describe "#replace" do
    it "replaces endpoints for a hostname" do
      endpoints = [{address: "2a00:1098:4c4::1", site: "all"}]
      expect(client).to receive(:put).with(
        "/proxy/endpoints/example.com/www",
        body: {endpoints: endpoints}
      )
      proxy.replace("example.com", "www", endpoints)
    end
  end

  describe "#add" do
    it "adds endpoints for a hostname" do
      endpoints = [{address: "2a00:1098:4c4::1", site: "all"}]
      expect(client).to receive(:post).with(
        "/proxy/endpoints/example.com/www",
        body: {endpoints: endpoints}
      )
      proxy.add("example.com", "www", endpoints)
    end
  end

  describe "#delete" do
    it "deletes all endpoints for a hostname" do
      expect(client).to receive(:delete).with("/proxy/endpoints/example.com/www")
      proxy.delete("example.com", "www")
    end
  end

  describe "#delete_endpoint" do
    it "deletes a specific endpoint" do
      expect(client).to receive(:delete).with("/proxy/endpoints/example.com/www/2a00:1098:4c4::1")
      proxy.delete_endpoint("example.com", "www", "2a00:1098:4c4::1")
    end

    it "deletes endpoint with specific site" do
      expect(client).to receive(:delete).with("/proxy/endpoints/example.com/www/2a00:1098:4c4::1/sov")
      proxy.delete_endpoint("example.com", "www", "2a00:1098:4c4::1", "sov")
    end
  end

  describe "#sites" do
    it "lists available proxy sites" do
      expect(client).to receive(:get).with("/proxy/sites").and_return(
        {"sites" => ["sov", "ams", "hex"]}
      )
      sites = proxy.sites
      expect(sites).to eq(["sov", "ams", "hex"])
    end
  end

  describe "#create_simple" do
    it "creates a simple proxy endpoint" do
      expect(client).to receive(:post).with(
        "/proxy/endpoints/example.com/staging",
        body: {endpoints: [{address: "2a00:1098:4c4::1", site: "all"}]}
      )
      proxy.create_simple("example.com", "staging", "2a00:1098:4c4::1")
    end

    it "creates endpoint with proxy_protocol enabled" do
      expect(client).to receive(:post).with(
        "/proxy/endpoints/example.com/staging",
        body: {endpoints: [{address: "2a00:1098:4c4::1", site: "all", proxy_protocol: true}]}
      )
      proxy.create_simple("example.com", "staging", "2a00:1098:4c4::1", proxy_protocol: true)
    end
  end
end

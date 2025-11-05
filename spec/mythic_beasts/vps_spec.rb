require "spec_helper"

RSpec.describe MythicBeasts::VPS do
  let(:client) { instance_double(MythicBeasts::Client) }
  let(:vps) { described_class.new(client) }

  describe "#list" do
    it "fetches all VPS servers" do
      expect(client).to receive(:get).with("/api/vps")
      vps.list
    end
  end

  describe "#get" do
    it "fetches a specific VPS" do
      expect(client).to receive(:get).with("/api/vps/my-server")
      vps.get("my-server")
    end
  end

  describe "#create" do
    it "creates a new VPS" do
      expected_body = {
        product: "VPSX16",
        name: "test-server"
      }

      expect(client).to receive(:post)
        .with("/beta/vps/servers", body: expected_body)

      vps.create(product: "VPSX16", name: "test-server")
    end

    it "includes SSH keys when provided" do
      expected_body = {
        product: "VPSX16",
        name: "test-server",
        ssh_keys: "ssh-rsa AAAAB3..."
      }

      expect(client).to receive(:post)
        .with("/beta/vps/servers", body: expected_body)

      vps.create(product: "VPSX16", name: "test-server", ssh_keys: "ssh-rsa AAAAB3...")
    end

    it "includes additional options" do
      expected_body = {
        product: "VPSX16",
        name: "test-server",
        disk_size: 20480,
        zone: "london"
      }

      expect(client).to receive(:post)
        .with("/beta/vps/servers", body: expected_body)

      vps.create(product: "VPSX16", name: "test-server", disk_size: 20480, zone: "london")
    end

    it "supports IPv6-only servers without IPv4" do
      expected_body = {
        product: "VPSX16",
        name: "test-server",
        ipv4: false
      }

      expect(client).to receive(:post)
        .with("/beta/vps/servers", body: expected_body)

      vps.create(product: "VPSX16", name: "test-server", ipv4: false)
    end
  end

  describe "#start" do
    it "starts a VPS" do
      expect(client).to receive(:post).with("/api/vps/my-server/start")
      vps.start("my-server")
    end
  end

  describe "#stop" do
    it "stops a VPS" do
      expect(client).to receive(:post).with("/api/vps/my-server/stop")
      vps.stop("my-server")
    end
  end

  describe "#restart" do
    it "restarts a VPS" do
      expect(client).to receive(:post).with("/api/vps/my-server/restart")
      vps.restart("my-server")
    end
  end

  describe "#delete" do
    it "deletes a VPS" do
      expect(client).to receive(:delete).with("/api/vps/my-server")
      vps.delete("my-server")
    end
  end

  describe "#console" do
    it "gets console access" do
      expect(client).to receive(:get).with("/api/vps/my-server/console")
      vps.console("my-server")
    end
  end

  describe "#zones" do
    it "fetches available zones/datacenters" do
      expect(client).to receive(:get).with("/beta/vps/zones")
      vps.zones
    end
  end

  describe "#images" do
    it "fetches available OS images" do
      expect(client).to receive(:get).with("/beta/vps/images")
      vps.images
    end
  end

  describe "#disk_sizes" do
    it "fetches available disk sizes" do
      expect(client).to receive(:get).with("/beta/vps/disk-sizes")
      vps.disk_sizes
    end
  end

  describe "#products" do
    it "fetches available products" do
      expect(client).to receive(:get).with("/beta/vps/products")
      vps.products
    end
  end
end

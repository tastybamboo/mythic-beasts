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
        name: "test-server",
        type: "VPS-2"
      }

      expect(client).to receive(:post)
        .with("/api/vps", body: expected_body)

      vps.create(name: "test-server", type: "VPS-2")
    end

    it "includes SSH key when provided" do
      expected_body = {
        name: "test-server",
        type: "VPS-2",
        ssh_key: "ssh-rsa AAAAB3..."
      }

      expect(client).to receive(:post)
        .with("/api/vps", body: expected_body)

      vps.create(name: "test-server", type: "VPS-2", ssh_key: "ssh-rsa AAAAB3...")
    end

    it "includes additional options" do
      expected_body = {
        name: "test-server",
        type: "VPS-2",
        disk: 50,
        memory: 4096
      }

      expect(client).to receive(:post)
        .with("/api/vps", body: expected_body)

      vps.create(name: "test-server", type: "VPS-2", disk: 50, memory: 4096)
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
      expect(client).to receive(:get).with("/api/vps/zones")
      vps.zones
    end
  end

  describe "#types" do
    it "fetches available VPS types/plans" do
      expect(client).to receive(:get).with("/api/vps/types")
      vps.types
    end
  end
end

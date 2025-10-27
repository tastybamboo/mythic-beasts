require "spec_helper"

RSpec.describe MythicBeasts::DNS do
  let(:client) { instance_double(MythicBeasts::Client) }
  let(:dns) { described_class.new(client) }

  describe "#zones" do
    it "fetches all zones" do
      expect(client).to receive(:get).with("/dns/v2/zones")
      dns.zones
    end
  end

  describe "#records" do
    it "fetches records for a zone" do
      expect(client).to receive(:get).with("/dns/v2/zones/example.com/records")
      dns.records("example.com")
    end
  end

  describe "#get_record" do
    it "fetches specific record by host and type" do
      expect(client).to receive(:get).with("/dns/v2/zones/example.com/records/www/A")
      dns.get_record("example.com", "www", "A")
    end
  end

  describe "#create_records" do
    it "creates multiple records" do
      records = [
        {host: "www", ttl: 300, type: "A", data: "1.2.3.4"},
        {host: "mail", ttl: 300, type: "A", data: "1.2.3.5"}
      ]

      expect(client).to receive(:post)
        .with("/dns/v2/zones/example.com/records", body: {records: records})

      dns.create_records("example.com", records)
    end
  end

  describe "#update_records" do
    it "updates records without filters" do
      records = [{host: "www", ttl: 600, type: "A", data: "1.2.3.4"}]

      expect(client).to receive(:put)
        .with("/dns/v2/zones/example.com/records", body: {records: records})

      dns.update_records("example.com", records)
    end

    it "updates records with host filter" do
      records = [{host: "www", ttl: 600, type: "A", data: "1.2.3.4"}]

      expect(client).to receive(:put)
        .with("/dns/v2/zones/example.com/records/www", body: {records: records})

      dns.update_records("example.com", records, host: "www")
    end

    it "updates records with host and type filters" do
      records = [{host: "www", ttl: 600, type: "A", data: "1.2.3.4"}]

      expect(client).to receive(:put)
        .with("/dns/v2/zones/example.com/records/www/A", body: {records: records})

      dns.update_records("example.com", records, host: "www", type: "A")
    end
  end

  describe "#delete_records" do
    it "deletes all records in zone" do
      expect(client).to receive(:delete)
        .with("/dns/v2/zones/example.com/records", params: {})

      dns.delete_records("example.com")
    end

    it "deletes records with host filter" do
      expect(client).to receive(:delete)
        .with("/dns/v2/zones/example.com/records/www", params: {})

      dns.delete_records("example.com", host: "www")
    end

    it "deletes records with host and type filters" do
      expect(client).to receive(:delete)
        .with("/dns/v2/zones/example.com/records/www/A", params: {})

      dns.delete_records("example.com", host: "www", type: "A")
    end

    it "deletes records with data filter" do
      expect(client).to receive(:delete)
        .with("/dns/v2/zones/example.com/records/www/A", params: {data: "1.2.3.4"})

      dns.delete_records("example.com", host: "www", type: "A", data: "1.2.3.4")
    end
  end

  describe "#dynamic_update" do
    it "updates dynamic DNS record" do
      expect(client).to receive(:put).with("/dns/v2/dynamic/home.example.com")
      dns.dynamic_update("home.example.com")
    end
  end

  describe "convenience methods" do
    describe "#create_a_record" do
      it "creates an A record with correct parameters" do
        expected_body = {
          records: [{
            host: "www",
            ttl: 300,
            type: "A",
            data: "1.2.3.4"
          }]
        }

        expect(client).to receive(:post)
          .with("/dns/v2/zones/example.com/records", body: expected_body)

        dns.create_a_record("example.com", "www", "1.2.3.4", ttl: 300)
      end
    end

    describe "#create_aaaa_record" do
      it "creates an AAAA record" do
        expected_body = {
          records: [{
            host: "www",
            ttl: 300,
            type: "AAAA",
            data: "2001:db8::1"
          }]
        }

        expect(client).to receive(:post)
          .with("/dns/v2/zones/example.com/records", body: expected_body)

        dns.create_aaaa_record("example.com", "www", "2001:db8::1")
      end
    end

    describe "#create_cname_record" do
      it "creates a CNAME record" do
        expected_body = {
          records: [{
            host: "www",
            ttl: 300,
            type: "CNAME",
            data: "example.com"
          }]
        }

        expect(client).to receive(:post)
          .with("/dns/v2/zones/example.com/records", body: expected_body)

        dns.create_cname_record("example.com", "www", "example.com")
      end
    end

    describe "#create_mx_record" do
      it "creates an MX record" do
        expected_body = {
          records: [{
            host: "@",
            ttl: 300,
            type: "MX",
            data: "10 mail.example.com"
          }]
        }

        expect(client).to receive(:post)
          .with("/dns/v2/zones/example.com/records", body: expected_body)

        dns.create_mx_record("example.com", "@", 10, "mail.example.com")
      end
    end

    describe "#create_txt_record" do
      it "creates a TXT record" do
        expected_body = {
          records: [{
            host: "@",
            ttl: 300,
            type: "TXT",
            data: "v=spf1 mx ~all"
          }]
        }

        expect(client).to receive(:post)
          .with("/dns/v2/zones/example.com/records", body: expected_body)

        dns.create_txt_record("example.com", "@", "v=spf1 mx ~all")
      end
    end
  end
end

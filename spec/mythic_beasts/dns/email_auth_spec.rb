require "spec_helper"

RSpec.describe MythicBeasts::DNS::EmailAuth do
  let(:client) { instance_double(MythicBeasts::Client) }
  let(:dns) { MythicBeasts::DNS.new(client) }
  let(:email_auth) { described_class.new(dns, "example.com") }

  def txt_response(records)
    {"records" => records.map { |data| {"data" => data} }}
  end

  describe "#verify_spf" do
    it "validates a correct SPF record" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 include:_spf.google.com ~all"]))

      result = email_auth.verify_spf

      expect(result.valid?).to be true
      expect(result.record).to eq("v=spf1 include:_spf.google.com ~all")
      expect(result.errors).to be_empty
      expect(result.details[:lookup_count]).to eq(1)
    end

    it "returns error when no SPF record exists" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_raise(MythicBeasts::NotFoundError)

      result = email_auth.verify_spf

      expect(result.valid?).to be false
      expect(result.errors).to include("No SPF record found")
    end

    it "returns error when TXT records exist but none are SPF" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["google-site-verification=abc123"]))

      result = email_auth.verify_spf

      expect(result.valid?).to be false
      expect(result.errors).to include("No SPF record found")
    end

    it "returns error for multiple SPF records (RFC 7208 violation)" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response([
          "v=spf1 include:_spf.google.com ~all",
          "v=spf1 include:mailgun.org ~all"
        ]))

      result = email_auth.verify_spf

      expect(result.valid?).to be false
      expect(result.errors).to include("Multiple SPF records found (RFC 7208 violation)")
    end

    it "returns error when DNS lookups exceed 10" do
      spf = "v=spf1 " + (1..11).map { |i| "include:spf#{i}.example.com" }.join(" ") + " ~all"
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response([spf]))

      result = email_auth.verify_spf

      expect(result.valid?).to be false
      expect(result.errors.first).to match(/11 DNS lookups/)
      expect(result.details[:lookup_count]).to eq(11)
    end

    it "warns when DNS lookups approach the limit" do
      spf = "v=spf1 " + (1..9).map { |i| "include:spf#{i}.example.com" }.join(" ") + " ~all"
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response([spf]))

      result = email_auth.verify_spf

      expect(result.valid?).to be true
      expect(result.warnings.first).to match(/9 DNS lookups/)
    end

    it "warns about misplaced 'all' mechanism" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 ~all include:_spf.google.com"]))

      result = email_auth.verify_spf

      expect(result.warnings).to include("SPF 'all' mechanism should be at the end")
    end

    it "warns about semicolons in SPF record" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 include:_spf.google.com; ~all"]))

      result = email_auth.verify_spf

      expect(result.warnings).to include("SPF record contains semicolons (check if intentional)")
    end

    it "counts multiple lookup mechanism types correctly" do
      spf = "v=spf1 a mx include:_spf.google.com redirect:example.net ~all"
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response([spf]))

      result = email_auth.verify_spf

      expect(result.details[:lookup_count]).to eq(4)
    end
  end

  describe "#verify_dmarc" do
    it "validates a correct DMARC record with all recommended tags" do
      dmarc = "v=DMARC1; p=reject; rua=mailto:dmarc@example.com; ruf=mailto:forensics@example.com"
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response([dmarc]))

      result = email_auth.verify_dmarc

      expect(result.valid?).to be true
      expect(result.record).to eq(dmarc)
      expect(result.errors).to be_empty
      expect(result.warnings).to be_empty
      expect(result.details[:policy]).to eq("reject")
    end

    it "returns warning (not error) when no DMARC record exists" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_raise(MythicBeasts::NotFoundError)

      result = email_auth.verify_dmarc

      expect(result.valid?).to be true
      expect(result.errors).to be_empty
      expect(result.warnings).to include("No DMARC record found (recommended for email authentication)")
    end

    it "returns error for multiple DMARC records" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response([
          "v=DMARC1; p=none",
          "v=DMARC1; p=reject"
        ]))

      result = email_auth.verify_dmarc

      expect(result.valid?).to be false
      expect(result.errors).to include("Multiple DMARC records found")
    end

    it "returns error when DMARC record has invalid version tag" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC2; p=reject"]))

      result = email_auth.verify_dmarc

      expect(result.valid?).to be false
      expect(result.errors).to include("DMARC record doesn't start with 'v=DMARC1'")
    end

    it "returns error when DMARC record is missing required 'p' tag" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; rua=mailto:dmarc@example.com"]))

      result = email_auth.verify_dmarc

      expect(result.valid?).to be false
      expect(result.errors).to include("DMARC record missing required 'p' tag")
    end

    it "returns error for invalid DMARC policy value" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=invalid"]))

      result = email_auth.verify_dmarc

      expect(result.valid?).to be false
      expect(result.errors).to include("Invalid DMARC policy: invalid")
    end

    it "warns when rua tag is missing" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=none"]))

      result = email_auth.verify_dmarc

      expect(result.valid?).to be true
      expect(result.warnings).to include("DMARC record missing 'rua' tag (no aggregate reports)")
    end

    it "accepts all valid DMARC policy values" do
      %w[none quarantine reject].each do |policy|
        expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
          .and_return(txt_response(["v=DMARC1; p=#{policy}; rua=mailto:d@example.com"]))

        result = email_auth.verify_dmarc

        expect(result.valid?).to be true
        expect(result.details[:policy]).to eq(policy)
      end
    end
  end

  describe "#verify_dkim" do
    it "validates a correct DKIM record" do
      # A valid base64 key (short for testing)
      dkim = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ=="
      expect(dns).to receive(:get_record).with("example.com", "google._domainkey", "TXT")
        .and_return(txt_response([dkim]))

      result = email_auth.verify_dkim("google")

      expect(result.valid?).to be true
      expect(result.record).to eq(dkim)
      expect(result.errors).to be_empty
      expect(result.details[:selector]).to eq("google")
    end

    it "returns error when no DKIM record exists" do
      expect(dns).to receive(:get_record).with("example.com", "google._domainkey", "TXT")
        .and_raise(MythicBeasts::NotFoundError)

      result = email_auth.verify_dkim("google")

      expect(result.valid?).to be false
      expect(result.errors).to include("No DKIM record found for selector 'google'")
    end

    it "returns error when DKIM record is missing v=DKIM1" do
      expect(dns).to receive(:get_record).with("example.com", "test._domainkey", "TXT")
        .and_return(txt_response(["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ=="]))

      result = email_auth.verify_dkim("test")

      expect(result.valid?).to be false
      expect(result.errors).to include("DKIM record doesn't contain 'v=DKIM1'")
    end

    it "returns error when DKIM record has no public key" do
      expect(dns).to receive(:get_record).with("example.com", "test._domainkey", "TXT")
        .and_return(txt_response(["v=DKIM1; k=rsa"]))

      result = email_auth.verify_dkim("test")

      expect(result.valid?).to be false
      expect(result.errors).to include("DKIM record missing or invalid public key (p= tag)")
    end

    it "returns error for invalid base64 public key" do
      # "YWJj" is valid base64, but "YWJ" with trailing "A" padding is not strict base64
      expect(dns).to receive(:get_record).with("example.com", "test._domainkey", "TXT")
        .and_return(txt_response(["v=DKIM1; k=rsa; p=notvalidbase64padding=="]))

      result = email_auth.verify_dkim("test")

      expect(result.valid?).to be false
      expect(result.errors).to include("DKIM public key is not valid base64")
    end

    it "joins multiple TXT record strings" do
      dkim_part1 = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQ"
      dkim_part2 = "EBAQUAA4GNADCBiQ=="
      expect(dns).to receive(:get_record).with("example.com", "test._domainkey", "TXT")
        .and_return(txt_response([dkim_part1, dkim_part2]))

      result = email_auth.verify_dkim("test")

      expect(result.record).to eq(dkim_part1 + dkim_part2)
    end
  end

  describe "#verify" do
    it "aggregates results from all checks when all pass" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 include:_spf.google.com ~all"]))
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=reject; rua=mailto:d@example.com"]))
      expect(dns).to receive(:get_record).with("example.com", "google._domainkey", "TXT")
        .and_return(txt_response(["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ=="]))

      result = email_auth.verify(dkim_selectors: ["google"])

      expect(result.valid?).to be true
      expect(result.errors).to be_empty
      expect(result.spf.valid?).to be true
      expect(result.dmarc.valid?).to be true
      expect(result.dkim["google"].valid?).to be true
    end

    it "collects errors and warnings from all checks" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_raise(MythicBeasts::NotFoundError)
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=none"]))
      expect(dns).to receive(:get_record).with("example.com", "test._domainkey", "TXT")
        .and_raise(MythicBeasts::NotFoundError)

      result = email_auth.verify(dkim_selectors: ["test"])

      expect(result.valid?).to be false
      expect(result.errors).to include("No SPF record found")
      expect(result.errors).to include("No DKIM record found for selector 'test'")
      expect(result.warnings).to include("DMARC record missing 'rua' tag (no aggregate reports)")
    end

    it "works with no DKIM selectors" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 ~all"]))
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=reject; rua=mailto:d@example.com"]))

      result = email_auth.verify

      expect(result.valid?).to be true
      expect(result.dkim).to be_empty
    end

    it "checks multiple DKIM selectors" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 ~all"]))
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=reject; rua=mailto:d@example.com"]))
      expect(dns).to receive(:get_record).with("example.com", "sel1._domainkey", "TXT")
        .and_return(txt_response(["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ=="]))
      expect(dns).to receive(:get_record).with("example.com", "sel2._domainkey", "TXT")
        .and_raise(MythicBeasts::NotFoundError)

      result = email_auth.verify(dkim_selectors: ["sel1", "sel2"])

      expect(result.valid?).to be false
      expect(result.dkim["sel1"].valid?).to be true
      expect(result.dkim["sel2"].valid?).to be false
    end
  end

  describe "DNS delegation methods" do
    it "delegates verify_email_auth to EmailAuth" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 ~all"]))
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_raise(MythicBeasts::NotFoundError)

      result = dns.verify_email_auth("example.com")

      expect(result).to be_a(MythicBeasts::DNS::EmailAuth::Result)
      expect(result.valid?).to be true
    end

    it "delegates verify_spf to EmailAuth" do
      expect(dns).to receive(:get_record).with("example.com", "@", "TXT")
        .and_return(txt_response(["v=spf1 ~all"]))

      result = dns.verify_spf("example.com")

      expect(result).to be_a(MythicBeasts::DNS::EmailAuth::CheckResult)
    end

    it "delegates verify_dmarc to EmailAuth" do
      expect(dns).to receive(:get_record).with("example.com", "_dmarc", "TXT")
        .and_return(txt_response(["v=DMARC1; p=reject; rua=mailto:d@example.com"]))

      result = dns.verify_dmarc("example.com")

      expect(result).to be_a(MythicBeasts::DNS::EmailAuth::CheckResult)
    end

    it "delegates verify_dkim to EmailAuth" do
      expect(dns).to receive(:get_record).with("example.com", "google._domainkey", "TXT")
        .and_return(txt_response(["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ=="]))

      result = dns.verify_dkim("example.com", "google")

      expect(result).to be_a(MythicBeasts::DNS::EmailAuth::CheckResult)
    end
  end
end

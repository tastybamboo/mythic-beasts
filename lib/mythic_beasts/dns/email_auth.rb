# frozen_string_literal: true

module MythicBeasts
  class DNS
    # Validates SPF, DKIM, and DMARC DNS records for a domain
    #
    # Uses the Mythic Beasts DNS API to fetch TXT records and validate
    # email authentication configuration. Returns structured results
    # rather than printing output, so callers can format as needed.
    #
    # @example Verify all email auth records
    #   result = client.dns.verify_email_auth("example.com", dkim_selectors: ["google", "mailchimp"])
    #   result.valid?      # => true/false
    #   result.errors       # => ["No SPF record found"]
    #   result.spf.record   # => "v=spf1 include:_spf.google.com ~all"
    #
    # @see https://www.mythic-beasts.com/support/api/dnsv2
    class EmailAuth
      # Aggregated result of all email authentication checks
      Result = Struct.new(:spf, :dmarc, :dkim, :errors, :warnings, keyword_init: true) do
        # @return [Boolean] true if no errors were found across all checks
        def valid?
          errors.empty?
        end
      end

      # Result of an individual check (SPF, DMARC, or DKIM)
      CheckResult = Struct.new(:record, :valid, :errors, :warnings, :details, keyword_init: true) do
        # @return [Boolean] true if this individual check passed
        def valid?
          valid
        end
      end

      SPF_LOOKUP_MECHANISMS = %w[include a mx ptr exists redirect].freeze
      VALID_DMARC_POLICIES = %w[none quarantine reject].freeze

      # @param dns [MythicBeasts::DNS] the DNS client instance
      # @param zone [String] the domain/zone to verify
      def initialize(dns, zone)
        @dns = dns
        @zone = zone
      end

      # Run all email authentication checks
      #
      # @param dkim_selectors [Array<String>] DKIM selectors to check (e.g., ["google", "mailchimp"])
      # @return [Result] aggregated result with per-check details
      def verify(dkim_selectors: [])
        spf_result = verify_spf
        dmarc_result = verify_dmarc
        dkim_results = dkim_selectors.map { |selector| [selector, verify_dkim(selector)] }.to_h

        all_errors = spf_result.errors + dmarc_result.errors +
          dkim_results.values.flat_map(&:errors)
        all_warnings = spf_result.warnings + dmarc_result.warnings +
          dkim_results.values.flat_map(&:warnings)

        Result.new(
          spf: spf_result,
          dmarc: dmarc_result,
          dkim: dkim_results,
          errors: all_errors,
          warnings: all_warnings
        )
      end

      # Verify SPF record for the zone
      #
      # Fetches TXT records at the zone root and filters for v=spf1 records.
      # Validates against RFC 7208: single record, valid syntax, <=10 DNS lookups.
      #
      # @return [CheckResult] with :lookup_count in details
      def verify_spf
        errors = []
        warnings = []

        txt_records = fetch_txt_records("@")
        spf_records = txt_records.select { |r| r.start_with?("v=spf1") }

        if spf_records.empty?
          return CheckResult.new(record: nil, valid: false,
            errors: ["No SPF record found"], warnings: [], details: {})
        end

        if spf_records.length > 1
          return CheckResult.new(record: spf_records, valid: false,
            errors: ["Multiple SPF records found (RFC 7208 violation)"],
            warnings: [], details: {})
        end

        spf = spf_records.first

        # Validate syntax
        if spf.match?(/\ball\b/) && !spf.match?(/[~\-+?]all\s*$/)
          warnings << "SPF 'all' mechanism should be at the end"
        end

        if spf.include?(";")
          warnings << "SPF record contains semicolons (check if intentional)"
        end

        # Count DNS lookups
        lookup_count = count_spf_lookups(spf)
        if lookup_count > 10
          errors << "SPF has #{lookup_count} DNS lookups (max 10 allowed per RFC 7208)"
        elsif lookup_count > 8
          warnings << "SPF has #{lookup_count} DNS lookups (approaching limit of 10)"
        end

        CheckResult.new(
          record: spf, valid: errors.empty?, errors: errors, warnings: warnings,
          details: {lookup_count: lookup_count}
        )
      end

      # Verify DMARC record for the zone
      #
      # Fetches TXT records at _dmarc.{zone} and validates syntax,
      # required p= tag, and recommended rua= tag.
      #
      # @return [CheckResult] with :policy and :tags in details
      def verify_dmarc
        errors = []
        warnings = []

        txt_records = fetch_txt_records("_dmarc")

        if txt_records.empty?
          return CheckResult.new(record: nil, valid: true,
            errors: [],
            warnings: ["No DMARC record found (recommended for email authentication)"],
            details: {})
        end

        if txt_records.length > 1
          return CheckResult.new(record: txt_records, valid: false,
            errors: ["Multiple DMARC records found"], warnings: [], details: {})
        end

        dmarc = txt_records.first

        unless dmarc.start_with?("v=DMARC1")
          return CheckResult.new(record: dmarc, valid: false,
            errors: ["DMARC record doesn't start with 'v=DMARC1'"],
            warnings: [], details: {})
        end

        tags = parse_dmarc_tags(dmarc)

        if tags["p"]
          unless VALID_DMARC_POLICIES.include?(tags["p"])
            errors << "Invalid DMARC policy: #{tags["p"]}"
          end
        else
          errors << "DMARC record missing required 'p' tag"
        end

        unless tags["rua"]
          warnings << "DMARC record missing 'rua' tag (no aggregate reports)"
        end

        CheckResult.new(
          record: dmarc, valid: errors.empty?, errors: errors, warnings: warnings,
          details: {policy: tags["p"], tags: tags}
        )
      end

      # Verify DKIM record for a specific selector
      #
      # Fetches TXT records at {selector}._domainkey.{zone} and validates
      # the presence of v=DKIM1 and a valid base64 public key.
      #
      # @param selector [String] the DKIM selector (e.g., "google", "mailchimp")
      # @return [CheckResult]
      def verify_dkim(selector)
        errors = []
        warnings = []

        txt_records = fetch_txt_records("#{selector}._domainkey")

        if txt_records.empty?
          return CheckResult.new(record: nil, valid: false,
            errors: ["No DKIM record found for selector '#{selector}'"],
            warnings: [], details: {selector: selector})
        end

        dkim = txt_records.join

        unless dkim.match?(/v=DKIM1/i)
          return CheckResult.new(record: dkim, valid: false,
            errors: ["DKIM record doesn't contain 'v=DKIM1'"],
            warnings: warnings, details: {selector: selector})
        end

        key_match = dkim.match(/p=([A-Za-z0-9+\/=]+)/)
        unless key_match
          return CheckResult.new(record: dkim, valid: false,
            errors: ["DKIM record missing or invalid public key (p= tag)"],
            warnings: warnings, details: {selector: selector})
        end

        # Validate base64 encoding (without requiring the base64 gem)
        key = key_match[1]
        unless valid_base64?(key)
          errors << "DKIM public key is not valid base64"
        end

        CheckResult.new(
          record: dkim, valid: errors.empty?, errors: errors, warnings: warnings,
          details: {selector: selector, key_length: key.length}
        )
      end

      private

      # Fetch TXT record data from the DNS API
      #
      # @param host [String] the hostname within the zone
      # @return [Array<String>] array of TXT record data values
      def fetch_txt_records(host)
        response = @dns.get_record(@zone, host, "TXT")
        records = response["records"] || []
        records.map { |r| r["data"] }
      rescue MythicBeasts::NotFoundError
        []
      end

      # Count DNS lookup mechanisms in an SPF record
      #
      # @param spf [String] the SPF record text
      # @return [Integer] number of DNS-querying mechanisms
      def count_spf_lookups(spf)
        SPF_LOOKUP_MECHANISMS.sum { |mechanism| spf.scan(/\b#{mechanism}[:\s]/i).length }
      end

      # Validate strict base64 encoding without requiring the base64 gem
      #
      # @param str [String] the string to validate
      # @return [Boolean] true if valid base64
      def valid_base64?(str)
        return false if str.empty?
        return false unless str.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
        str.length % 4 == 0
      end

      # Parse DMARC tag-value pairs
      #
      # @param dmarc [String] the DMARC record text
      # @return [Hash<String, String>] tag => value pairs
      def parse_dmarc_tags(dmarc)
        tags = {}
        dmarc.gsub(/v=DMARC1;?\s*/, "").split(";").each do |tag|
          next if tag.strip.empty?
          key, value = tag.split("=", 2).map(&:strip)
          tags[key] = value if key && value
        end
        tags
      end
    end
  end
end

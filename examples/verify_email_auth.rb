#!/usr/bin/env ruby
# frozen_string_literal: true

# Verify email authentication DNS records (SPF, DKIM, DMARC) for a domain.
#
# Usage:
#   ruby verify_email_auth.rb example.com
#   ruby verify_email_auth.rb example.com google,mailchimp    # check DKIM selectors

require "bundler/setup"
require "mythic_beasts"

MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

domain = ARGV[0] || ENV.fetch("DOMAIN", nil)
unless domain
  puts "Usage: ruby #{__FILE__} <domain> [dkim_selectors]"
  exit 1
end

dkim_selectors = ARGV[1]&.split(",") || []

puts "Email Authentication Verification for #{domain}"
puts "=" * 60

result = MythicBeasts.client.dns.verify_email_auth(domain, dkim_selectors: dkim_selectors)

# SPF
puts "\nSPF:"
if result.spf.record
  puts "  Record: #{result.spf.record}"
  puts "  Lookups: #{result.spf.details[:lookup_count]}/10" if result.spf.details[:lookup_count]
else
  puts "  Not found"
end
result.spf.errors.each { |e| puts "  ERROR: #{e}" }
result.spf.warnings.each { |w| puts "  WARNING: #{w}" }

# DMARC
puts "\nDMARC:"
if result.dmarc.record
  puts "  Record: #{result.dmarc.record}"
  puts "  Policy: #{result.dmarc.details[:policy]}" if result.dmarc.details[:policy]
else
  puts "  Not found"
end
result.dmarc.errors.each { |e| puts "  ERROR: #{e}" }
result.dmarc.warnings.each { |w| puts "  WARNING: #{w}" }

# DKIM
result.dkim.each do |selector, check|
  puts "\nDKIM (#{selector}):"
  if check.record
    display = (check.record.length > 80) ? "#{check.record[0..80]}..." : check.record
    puts "  Record: #{display}"
  else
    puts "  Not found"
  end
  check.errors.each { |e| puts "  ERROR: #{e}" }
  check.warnings.each { |w| puts "  WARNING: #{w}" }
end

# Summary
puts "\n" + "=" * 60
if result.valid?
  puts "All checks passed."
else
  puts "#{result.errors.length} error(s), #{result.warnings.length} warning(s)"
end

exit(result.valid? ? 0 : 1)

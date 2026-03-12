#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "mythic_beasts"
require "json"

MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

domain = ARGV[0] || ENV.fetch("DOMAIN", "neurobetter.org")

puts "Fetching DNS records for #{domain}...\n\n"

begin
  response = MythicBeasts.client.dns.records(domain)
  records = response["records"] || []

  records.each do |record|
    host = (record["host"] == "@") ? domain : "#{record["host"]}.#{domain}"
    puts host
    puts "  Type: #{record["type"]}"
    puts "  TTL:  #{record["ttl"]}"
    puts "  Data: #{record["data"]}"
    puts
  end

  puts "Total: #{records.length} records"
rescue MythicBeasts::Error => e
  puts "Error: #{e.message}"
  exit 1
end

#!/usr/bin/env ruby
# frozen_string_literal: true

# Sync DNS records from a simple YAML file to Mythic Beasts DNS.
#
# YAML format (records.yaml):
#   example.com:
#     "@":
#       A:
#         - data: "1.2.3.4"
#           ttl: 300
#       MX:
#         - data: "10 mail.example.com."
#           ttl: 300
#       TXT:
#         - data: "v=spf1 include:_spf.google.com ~all"
#           ttl: 300
#     www:
#       CNAME:
#         - data: "example.com."
#           ttl: 300
#
# Usage:
#   ruby sync_dns.rb records.yaml              # dry run (shows diff)
#   ruby sync_dns.rb records.yaml --apply      # apply changes

require "bundler/setup"
require "mythic_beasts"
require "yaml"

MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

dns = MythicBeasts.client.dns
apply = ARGV.delete("--apply")
yaml_file = ARGV[0]

unless yaml_file && File.exist?(yaml_file)
  puts "Usage: ruby #{__FILE__} <records.yaml> [--apply]"
  exit 1
end

desired = YAML.load_file(yaml_file)

desired.each do |zone, hosts|
  puts "=== #{zone} ==="

  # Fetch current records
  current_response = dns.records(zone)
  current_records = current_response["records"] || []
  current_by_host_type = current_records.group_by { |r| [r["host"], r["type"]] }

  changes = 0

  hosts.each do |host, types|
    types.each do |type, records|
      current = current_by_host_type[[host, type]] || []
      current_set = current.map { |r| {data: r["data"], ttl: r["ttl"]} }.to_set
      desired_set = records.map { |r| {data: r["data"], ttl: r["ttl"]} }.to_set

      next if current_set == desired_set

      changes += 1
      puts "\n  #{host}/#{type}:"
      (current_set - desired_set).each { |r| puts "    - #{r[:data]} (TTL: #{r[:ttl]})" }
      (desired_set - current_set).each { |r| puts "    + #{r[:data]} (TTL: #{r[:ttl]})" }

      if apply
        api_records = records.map { |r| {data: r["data"], ttl: r["ttl"]} }
        dns.update_records(zone, api_records, host: host, type: type)
        puts "    Applied."
      end
    end
  end

  if changes == 0
    puts "  No changes needed."
  elsif !apply
    puts "\n  #{changes} change(s) detected. Run with --apply to sync."
  else
    puts "\n  #{changes} change(s) applied."
  end
  puts
end

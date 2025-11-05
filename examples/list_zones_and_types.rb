#!/usr/bin/env ruby
# Example: List available zones and VPS types from Mythic Beasts API

require "bundler/setup"
require "mythic_beasts"

# Configure with your API credentials
MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

puts "🌍 Available Zones/Datacenters:"
puts "=" * 60

begin
  zones = MythicBeasts.client.vps.zones

  if zones.is_a?(Array) && zones.any?
    zones.each_with_index do |zone, i|
      puts "#{i + 1}. #{zone}"
    end
  else
    puts "Response: #{zones.inspect}"
  end
rescue MythicBeasts::Error => e
  puts "Error fetching zones: #{e.message}"
  puts "\nNote: Check your API credentials are set correctly."
end

puts "\n📦 Available VPS Types/Plans:"
puts "=" * 60

begin
  types = MythicBeasts.client.vps.types

  if types.is_a?(Array) && types.any?
    types.each_with_index do |type, i|
      puts "#{i + 1}. #{type}"
    end
  else
    puts "Response: #{types.inspect}"
  end
rescue MythicBeasts::Error => e
  puts "Error fetching VPS types: #{e.message}"
end

#!/usr/bin/env ruby
require "bundler/setup"
require "mythic_beasts"
require "json"

# Check if ENV vars are set
unless ENV["MYTHIC_BEASTS_API_KEY"] && ENV["MYTHIC_BEASTS_API_SECRET"]
  puts "Error: Please set MYTHIC_BEASTS_API_KEY and MYTHIC_BEASTS_API_SECRET"
  exit 1
end

MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

puts "💿 Available OS Images from API:"
puts "=" * 60
begin
  images = MythicBeasts.client.vps.images
  puts JSON.pretty_generate(images)
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.join("\n")
end

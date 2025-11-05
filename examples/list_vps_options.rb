#!/usr/bin/env ruby
require "bundler/setup"
require "mythic_beasts"
require "json"

# Load credentials from environment
unless ENV["MYTHIC_BEASTS_API_KEY"] && ENV["MYTHIC_BEASTS_API_SECRET"]
  require "dotenv/load"
end

MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

puts "🔍 Mythic Beasts VPS Options\n\n"

begin
  puts "📦 Available Products (monthly billing):"
  puts "=" * 60
  products = MythicBeasts.client.vps.products(billing: "monthly")
  if products.is_a?(Array)
    products.each do |product|
      puts "  #{product["code"] || product[:code]}: #{product["description"] || product[:description]}"
    end
  else
    puts "  #{JSON.pretty_generate(products)}"
  end
rescue => e
  puts "  Error: #{e.message}"
end

puts "\n💿 Available OS Images:"
puts "=" * 60
begin
  images = MythicBeasts.client.vps.images
  if images.is_a?(Array)
    images.each do |image|
      puts "  - #{image}"
    end
  else
    puts "  #{JSON.pretty_generate(images)}"
  end
rescue => e
  puts "  Error: #{e.message}"
end

puts "\n💾 Available Disk Sizes (SSD):"
puts "=" * 60
begin
  disk_sizes = MythicBeasts.client.vps.disk_sizes(storage_type: "ssd")
  if disk_sizes.is_a?(Array)
    disk_sizes.each do |size|
      gb = size.to_i / 1024
      puts "  - #{size} MB (#{gb} GB)"
    end
  else
    puts "  #{JSON.pretty_generate(disk_sizes)}"
  end
rescue => e
  puts "  Error: #{e.message}"
end

puts "\n🌍 Available Zones:"
puts "=" * 60
begin
  zones = MythicBeasts.client.vps.zones
  if zones.is_a?(Array)
    zones.each do |zone|
      puts "  - #{zone}"
    end
  else
    puts "  #{JSON.pretty_generate(zones)}"
  end
rescue => e
  puts "  Error: #{e.message}"
end

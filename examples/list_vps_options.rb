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
  puts "📦 Available Products:"
  puts "=" * 60
  products = MythicBeasts.client.vps.products
  if products.is_a?(Array)
    products.each do |product|
      code = product["code"] || product[:code]
      desc = product["description"] || product[:description]
      specs = product["specs"] || product[:specs] || {}
      ram = specs["ram"] || specs[:ram]
      cores = specs["cores"] || specs[:cores]
      puts "  #{code}: #{desc}"
      puts "    RAM: #{ram}MB, Cores: #{cores}" if ram && cores
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

puts "\n💾 Available Disk Sizes:"
puts "=" * 60
begin
  disk_sizes = MythicBeasts.client.vps.disk_sizes
  if disk_sizes.is_a?(Hash)
    ["ssd", "hdd"].each do |type|
      sizes = disk_sizes[type] || disk_sizes[type.to_sym] || []
      if sizes.any?
        puts "  #{type.upcase}:"
        sizes.sort.each do |size|
          gb = size.to_i / 1024
          puts "    - #{size} MB (#{gb} GB)"
        end
      end
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

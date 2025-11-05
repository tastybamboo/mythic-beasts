#!/usr/bin/env ruby
# Example: Provision a VPS server via Mythic Beasts API

require "bundler/setup"
require "mythic_beasts"

# Configure with your API credentials
MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

# Your SSH public key for server access
ssh_key_path = File.expand_path("~/.ssh/id_rsa.pub")
ssh_key_path = File.expand_path("~/.ssh/id_ed25519.pub") unless File.exist?(ssh_key_path)

unless File.exist?(ssh_key_path)
  puts "❌ No SSH public key found. Generate one with:"
  puts "   ssh-keygen -t ed25519"
  exit 1
end

ssh_key = File.read(ssh_key_path).strip

# Server configuration
server_config = {
  name: "my-test-server",
  type: "VPS-1",  # or VPS-2, VPS-3, etc.
  ssh_key: ssh_key,
  location: "london",  # or cambridge, amsterdam, fremont
  service: "my-service",  # Service/project name
  description: "Test server",
  notes: "Created via API example script"
}

puts "📦 Provisioning VPS Server"
puts "=" * 60
puts "Name: #{server_config[:name]}"
puts "Type: #{server_config[:type]}"
puts "Location: #{server_config[:location]}"
puts "Service: #{server_config[:service]}"
puts "=" * 60

print "\nProceed with provisioning? (yes/no): "
confirmation = gets.chomp.downcase

unless confirmation == "yes" || confirmation == "y"
  puts "❌ Cancelled."
  exit 0
end

begin
  result = MythicBeasts.client.vps.create(**server_config)

  puts "\n✅ Server provisioned successfully!"
  puts "\nResponse:"
  puts result.inspect

  if result.is_a?(Hash)
    puts "\n📋 Server Details:"
    puts "IP Address: #{result['ip'] || result[:ip] || 'Check control panel'}"
    puts "Server ID: #{result['id'] || result[:id] || 'N/A'}"
  end

  puts "\n💡 Next steps:"
  puts "1. Wait a few minutes for server to boot"
  puts "2. SSH in: ssh root@[ip-address]"
  puts "3. Check Mythic Beasts control panel for full details"
rescue MythicBeasts::Error => e
  puts "\n❌ Error: #{e.message}"
  exit 1
end

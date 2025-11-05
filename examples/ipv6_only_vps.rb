#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Provisioning an IPv6-only VPS (cheaper than with IPv4)
#
# IPv6-only servers cost less because they don't require IPv4 addresses.
# For services like HTTP/HTTPS, you can use Mythic Beasts' IPv4-to-IPv6 proxy
# to make your server accessible to IPv4-only clients.
#
# Supported proxy protocols:
# - HTTP (port 80)
# - HTTPS (port 443)
# - IMAPS (port 993)
# - SMTPS (port 465)
# - Gemini (port 1965)
#
# Setup process:
# 1. Provision IPv6-only VPS (ipv4: false)
# 2. Configure your domain in Mythic Beasts control panel
# 3. Setup IPv4-to-IPv6 proxy in control panel
# 4. Point DNS to proxy.mythic-beasts.com (CNAME or ANAME)
#
# Documentation: https://www.mythic-beasts.com/support/topics/proxy

require "bundler/setup"
require "mythic_beasts"

# Initialize the client with your credentials
client = MythicBeasts.client(
  api_key: ENV["MYTHIC_BEASTS_API_KEY"]
)

# Provision an IPv6-only VPS
puts "Provisioning IPv6-only VPS..."

result = client.vps.create(
  name: "my-ipv6-server",
  type: "VPS-2",
  ipv4: false,  # This makes it IPv6-only (cheaper!)
  ssh_key: File.read(File.expand_path("~/.ssh/id_ed25519.pub")).strip,
  location: "london",
  service: "my-app",
  description: "IPv6-only application server",
  notes: "Using IPv4-to-IPv6 proxy for web traffic"
)

if result["status"] == "success"
  puts "✓ Server provisioned successfully!"
  puts
  puts "Server details:"
  puts "  Name: #{result["name"]}"
  puts "  IPv6: #{result["ipv6"]&.first || "pending"}"
  puts "  IPv4: none (IPv6-only server)"
  puts
  puts "Next steps:"
  puts "1. Wait for server to finish provisioning"
  puts "2. Configure your domain in Mythic Beasts control panel"
  puts "3. Setup IPv4-to-IPv6 proxy for your domain:"
  puts "   - Navigate to: Control Panel > IPv4 to IPv6 Reverse Proxy"
  puts "   - Add hostname and select your domain"
  puts "   - Enter your server's IPv6 address: #{result["ipv6"]&.first}"
  puts "4. Update DNS records:"
  puts "   - Subdomain: CNAME to proxy.mythic-beasts.com"
  puts "   - Bare domain: ANAME to proxy.mythic-beasts.com"
  puts "5. Configure web server to use PROXY protocol (optional, for client IPs)"
  puts
  puts "Proxy configuration updates occur every 5 minutes."
else
  puts "✗ Failed to provision server:"
  puts result.inspect
  exit 1
end

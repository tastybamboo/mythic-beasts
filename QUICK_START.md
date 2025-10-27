# Quick Start Guide - mythic-beasts gem

**Author:** James Inman (@jfi)
**Repository:** https://github.com/tastybamboo/mythic-beasts

## Installation

```bash
gem install mythic-beasts
```

Or in your Gemfile:

```ruby
gem "mythic-beasts", "~> 0.1.0"
```

## Basic Usage

### Configuration

```ruby
require "mythic_beasts"

MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end
```

### DNS Management

```ruby
# List all zones
zones = MythicBeasts.client.dns.zones

# Get records for a zone
records = MythicBeasts.client.dns.records("example.com")

# Create an A record
MythicBeasts.client.dns.create_a_record(
  "example.com",
  "www",
  "1.2.3.4",
  ttl: 300
)

# Create multiple records at once
MythicBeasts.client.dns.create_records("example.com", [
  { host: "www", ttl: 300, type: "A", data: "1.2.3.4" },
  { host: "mail", ttl: 300, type: "A", data: "1.2.3.5" },
  { host: "@", ttl: 300, type: "MX", data: "10 mail.example.com" }
])

# Update records
MythicBeasts.client.dns.update_records(
  "example.com",
  [{ host: "www", ttl: 600, type: "A", data: "1.2.3.6" }],
  host: "www",
  type: "A"
)

# Delete records
MythicBeasts.client.dns.delete_records(
  "example.com",
  host: "www",
  type: "A"
)
```

### VPS Management

```ruby
# List all VPS servers
servers = MythicBeasts.client.vps.list

# Get server details
server = MythicBeasts.client.vps.get("my-server")

# Create a new VPS
MythicBeasts.client.vps.create(
  name: "my-new-server",
  type: "VPS-2",
  ssh_key: "ssh-rsa AAAAB3..."
)

# Control servers
MythicBeasts.client.vps.start("my-server")
MythicBeasts.client.vps.stop("my-server")
MythicBeasts.client.vps.restart("my-server")

# Delete a server
MythicBeasts.client.vps.delete("my-server")
```

## Error Handling

```ruby
begin
  MythicBeasts.client.dns.records("nonexistent.com")
rescue MythicBeasts::NotFoundError => e
  puts "Zone not found: #{e.message}"
rescue MythicBeasts::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue MythicBeasts::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue MythicBeasts::Error => e
  puts "General error: #{e.message}"
end
```

## Convenience Methods

```ruby
# A record
MythicBeasts.client.dns.create_a_record("example.com", "www", "1.2.3.4")

# AAAA record (IPv6)
MythicBeasts.client.dns.create_aaaa_record("example.com", "www", "2001:db8::1")

# CNAME record
MythicBeasts.client.dns.create_cname_record("example.com", "www", "example.com")

# MX record
MythicBeasts.client.dns.create_mx_record("example.com", "@", 10, "mail.example.com")

# TXT record
MythicBeasts.client.dns.create_txt_record("example.com", "@", "v=spf1 mx ~all")
```

## Dynamic DNS

```ruby
# Update record to current IP
MythicBeasts.client.dns.dynamic_update("home.example.com")
```

## Getting API Credentials

1. Log in to https://www.mythic-beasts.com
2. Go to "API Keys" in the control panel
3. Create a new API key
4. Save the Key ID and Secret

## Support

- **Documentation:** https://github.com/tastybamboo/mythic-beasts
- **Issues:** https://github.com/tastybamboo/mythic-beasts/issues
- **Author:** James Inman (james@otaina.co.uk)

## License

MIT License - Copyright (c) 2025 Otaina Limited

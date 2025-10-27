# Mythic Beasts Ruby Client

A Ruby gem for interacting with [Mythic Beasts](https://www.mythic-beasts.com/) APIs including DNS management, VPS provisioning, and domain management.

[![Gem Version](https://badge.fury.io/rb/mythic-beasts.svg)](https://badge.fury.io/rb/mythic-beasts)
[![CI](https://github.com/tastybamboo/mythic-beasts/workflows/CI/badge.svg)](https://github.com/tastybamboo/mythic-beasts/actions)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mythic-beasts'
```

And then execute:

```bash
bundle install
```

## Configuration

Get your API credentials from the [Mythic Beasts control panel](https://www.mythic-beasts.com/customer/api-keys).

```ruby
MythicBeasts.configure do |config|
  config.api_key = 'your_api_key'
  config.api_secret = 'your_api_secret'
end
```

Or create a client directly:

```ruby
client = MythicBeasts::Client.new(
  api_key: 'your_api_key',
  api_secret: 'your_api_secret'
)
```

## Usage

### DNS Management

```ruby
# Get all zones
zones = MythicBeasts.client.dns.zones

# Get records for a zone
records = MythicBeasts.client.dns.records('example.com')

# Create an A record
MythicBeasts.client.dns.create_a_record(
  'example.com',
  'www',
  '1.2.3.4',
  ttl: 300
)

# Create multiple records at once
MythicBeasts.client.dns.create_records('example.com', [
  { host: 'www', ttl: 300, type: 'A', data: '1.2.3.4' },
  { host: 'mail', ttl: 300, type: 'A', data: '1.2.3.5' },
  { host: '@', ttl: 300, type: 'MX', data: '10 mail.example.com' }
])

# Update records
MythicBeasts.client.dns.update_records(
  'example.com',
  [{ host: 'www', ttl: 600, type: 'A', data: '1.2.3.6' }],
  host: 'www',
  type: 'A'
)

# Delete records
MythicBeasts.client.dns.delete_records(
  'example.com',
  host: 'www',
  type: 'A'
)

# Dynamic DNS update (updates to client IP)
MythicBeasts.client.dns.dynamic_update('home.example.com')
```

### VPS Management

```ruby
# List all VPS servers
servers = MythicBeasts.client.vps.list

# Get server details
server = MythicBeasts.client.vps.get('my-server')

# Create a new VPS
MythicBeasts.client.vps.create(
  name: 'my-new-server',
  type: 'VPS-2',
  ssh_key: 'ssh-rsa AAAAB3...'
)

# Control servers
MythicBeasts.client.vps.start('my-server')
MythicBeasts.client.vps.stop('my-server')
MythicBeasts.client.vps.restart('my-server')

# Get console access
console = MythicBeasts.client.vps.console('my-server')

# Delete a server
MythicBeasts.client.vps.delete('my-server')
```

## Error Handling

The gem provides specific error classes:

```ruby
begin
  MythicBeasts.client.dns.records('nonexistent.com')
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

Available error classes:
- `MythicBeasts::Error` - Base error class
- `MythicBeasts::AuthenticationError` - Invalid credentials
- `MythicBeasts::NotFoundError` - Resource not found
- `MythicBeasts::ValidationError` - Invalid parameters
- `MythicBeasts::RateLimitError` - Rate limit exceeded
- `MythicBeasts::ServerError` - Server-side error

## Development

After checking out the repo:

```bash
bundle install
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tastybamboo/mythic-beasts.

## Author

**James Inman** ([@jfi](https://github.com/jfi))
- Email: james@otaina.co.uk
- GitHub: https://github.com/tastybamboo

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Copyright (c) 2025 Otaina Limited

## Resources

- [Mythic Beasts API Documentation](https://www.mythic-beasts.com/support/api)
- [DNS API v2 Docs](https://www.mythic-beasts.com/support/api/dnsv2)
- [VPS API Docs](https://www.mythic-beasts.com/support/api/vps)

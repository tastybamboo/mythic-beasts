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

#### Interactive CLI Tool (Recommended)

The gem includes an interactive CLI for easy VPS provisioning with arrow key navigation:

```bash
# With 1Password
op run --env-file=.env.1password -- mythic-beasts-provision

# Or with environment variables
export MYTHIC_BEASTS_API_KEY="your_key"
export MYTHIC_BEASTS_API_SECRET="your_secret"
mythic-beasts-provision
```

The CLI will guide you through:

- Selecting product (VPS size)
- Choosing datacenter/zone
- Picking OS image
- Setting disk size
- Network configuration (IPv4/IPv6)
- Server naming

#### Programmatic API

```ruby
# List available options
zones = MythicBeasts.client.vps.zones
products = MythicBeasts.client.vps.products
images = MythicBeasts.client.vps.images
disk_sizes = MythicBeasts.client.vps.disk_sizes

# List all VPS servers
servers = MythicBeasts.client.vps.list

# Get server details
server = MythicBeasts.client.vps.get('my-server')

# Create a new VPS
MythicBeasts.client.vps.create(
  product: 'VPSX16',  # Required: product code (e.g., VPSX16 = 2 cores, 4GB RAM)
  name: 'my-new-server',  # Optional: friendly name
  hostname: 'my-server',  # Optional: server hostname
  ssh_keys: 'ssh-rsa AAAAB3...',  # Optional: SSH public key(s)
  zone: 'cam',  # Optional: datacenter code (e.g., 'cam' for Cambridge)
  image: 'cloudinit-debian-bookworm.raw.gz',  # Optional: OS image
  disk_size: 20480,  # Required: disk size in MB
  ipv4: false  # Optional: false for IPv6-only (cheaper)
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

#### IPv6-Only Servers

Provision cheaper IPv6-only servers without IPv4 addresses. Perfect for services accessible via Mythic Beasts' IPv4-to-IPv6 proxy:

```ruby
# Create an IPv6-only VPS
MythicBeasts.client.vps.create(
  name: 'my-ipv6-server',
  type: 'VPS-2',
  ipv4: false,
  ssh_key: 'ssh-rsa AAAAB3...',
  location: 'london'
)
```

**IPv4-to-IPv6 Proxy Setup:**

1. Provision your IPv6-only VPS (as shown above)
2. In Mythic Beasts control panel, configure IPv4-to-IPv6 proxy
3. Point your domain's DNS to `proxy.mythic-beasts.com` (CNAME or ANAME)

**Supported proxy protocols:**

- HTTP (port 80) and HTTPS (port 443)
- IMAPS (port 993) and SMTPS (port 465)
- Gemini (port 1965)

See `examples/ipv6_only_vps.rb` for a complete working example with setup instructions.

**Documentation:** [IPv4 to IPv6 Proxy](https://www.mythic-beasts.com/support/topics/proxy)

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

## Examples

See the `examples/` directory for complete working examples:

- `examples/list_zones_and_types.rb` - List available zones and VPS types
- `examples/provision_vps.rb` - Provision a new VPS server
- `examples/ipv6_only_vps.rb` - Provision an IPv6-only VPS with proxy setup guide

Run examples with:

```bash
export MYTHIC_BEASTS_API_KEY=your_key
export MYTHIC_BEASTS_API_SECRET=your_secret
ruby examples/list_zones_and_types.rb
```

## Development

After checking out the repo, run the setup script to install dependencies and git hooks:

```bash
bin/setup
```

This will:

- Install all gem dependencies
- Set up lefthook git hooks that run before pushing

The pre-push hooks automatically run:

- `bundle exec standardrb` - Ruby code linting
- `npx markdownlint-cli2 "**/*.md"` - Markdown linting
- `bundle exec rspec` - Test suite
- `bundle exec bundler-audit check --update` - Security audit

You can also run these checks manually:

```bash
bundle exec rspec                           # Run tests
bundle exec standardrb                      # Run linter
npx markdownlint-cli2 "**/*.md"             # Run markdown linter
bundle exec bundler-audit check --update    # Run security audit
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tastybamboo/mythic-beasts.

## Author

**James Inman** ([@jfi](https://github.com/jfi))

- Email: james@otaina.co.uk
- GitHub: https://github.com/tastybamboo

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Copyright © 2025, Otaina Limited

## Resources

- [Mythic Beasts API Documentation](https://www.mythic-beasts.com/support/api)
- [DNS API v2 Docs](https://www.mythic-beasts.com/support/api/dnsv2)
- [VPS API Docs](https://www.mythic-beasts.com/support/api/vps)

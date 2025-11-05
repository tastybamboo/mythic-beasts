# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-11-05

### Added

- VPS zones listing method (`MythicBeasts.client.vps.zones`) to query available datacenters
- VPS types listing method (`MythicBeasts.client.vps.types`) to query available VPS plans
- Optional parameters for VPS creation: `location`, `service`, `description`, `notes`
- IPv6-only VPS provisioning support (`ipv4: false`) for cost savings
- Example scripts in `examples/` directory:
  - `list_zones_and_types.rb` - List available zones and VPS types
  - `provision_vps.rb` - Complete VPS provisioning example
  - `ipv6_only_vps.rb` - IPv6-only VPS with proxy setup guide
- Test coverage for IPv6-only VPS provisioning

### Changed

- Updated README with new VPS methods and examples
- Improved VPS create documentation with optional parameters
- Added IPv6-only servers documentation with proxy setup instructions

## [0.1.0] - 2025-01-27

### Features

- Initial release by James Inman (@jfi)
- OAuth2 authentication support with automatic token refresh
- DNS API v2 client with full CRUD operations
- VPS provisioning and management API
- Comprehensive error handling with custom exception classes
- Retry logic for transient failures
- Convenience methods for common DNS record types (A, AAAA, CNAME, MX, TXT)
- Complete test suite with RSpec and WebMock
- StandardRB compliance for code style

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-11-23

### Added in 0.2.0

- Interactive CLI tool `mythic-beasts-provision` with numbered menu navigation for VPS provisioning
- Interactive VPS management tool `mythic-beasts-manage-vps` with DNS and proxy configuration
- IPv4 to IPv6 Proxy API client (`MythicBeasts.client.proxy`) for managing proxy endpoints
  - List, create, replace, and delete proxy configurations
  - Support for all proxy sites (sov, ams, hex) or "all"
  - Convenience method `create_simple` for quick proxy setup
  - Full CRUD operations on proxy endpoints by domain/hostname/address
- DNS record verification after proxy configuration
- DNS management integration in `manage-vps` tool
- Comprehensive test coverage improvements:
  - Added tests for VPS newer API endpoints: `servers()`, `server()`, `reboot()`, `update()`, `unprovision()`, `iso_images()`, `create_with_identifier()`
  - Added test for Client PATCH method
  - Added test for Proxy client initialization
  - Test suite now contains 73 examples with 100% pass rate

### Changed in 0.2.0

- Replaced tty-prompt with simple numbered menus for better terminal compatibility (especially Ghostty)
- Smart bandwidth display: shows GB for >= 1024MB, MB otherwise

### Fixed in 0.2.0

- Zones endpoint now uses correct `/beta/vps/zones` path
- DNS verification now handles non-array responses correctly
- DNS records method name corrected in provision-vps tool
- VPS provisioning polling now waits for actual completion
- Status polling output now uses newlines properly
- IPv4 allocation during VPS provisioning
- Bandwidth display showing MB correctly instead of 0GB

## [0.1.3] - 2025-11-05

### Fixed in 0.1.3

- Bearer token authentication for VPS API endpoints - now sets Authorization header on each request
- VPS API endpoints now use correct `/beta/vps/*` paths instead of `/vps/*`
- Location header now captured from 202 Accepted responses for polling async operations
- Improved error messages to show API response body for better debugging

### Added to 0.1.3

- `VPS#images` method to list available OS images from `/beta/vps/images`
- `VPS#products` method to list available VPS products from `/beta/vps/products`
- `VPS#disk_sizes` method to list available disk sizes from `/beta/vps/disk-sizes`
- `VPS#zones` method to list available zones from `/beta/vps/zones`
- Example script `list_vps_options.rb` to display all available VPS configuration options

### Changed in 0.1.3

- VPS creation now requires `product:` parameter (e.g., `VPSX16`) instead of `type:`
- VPS creation now requires `ssh_keys:` parameter instead of `ssh_key:`
- VPS creation now uses `zone:` parameter instead of `location:`
- 404 errors now show the full URL and HTTP method that failed

## [0.1.2] - 2025-11-05

### Added in 0.1.2

- VPS zones listing method (`MythicBeasts.client.vps.zones`) to query available datacenters
- VPS types listing method (`MythicBeasts.client.vps.types`) to query available VPS plans
- Optional parameters for VPS creation: `location`, `service`, `description`, `notes`
- IPv6-only VPS provisioning support (`ipv4: false`) for cost savings
- Example scripts in `examples/` directory:
  - `list_zones_and_types.rb` - List available zones and VPS types
  - `provision_vps.rb` - Complete VPS provisioning example
  - `ipv6_only_vps.rb` - IPv6-only VPS with proxy setup guide
- Test coverage for IPv6-only VPS provisioning

### Changed in 0.1.2

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

# frozen_string_literal: true

module MythicBeasts
  # IPv4 to IPv6 Proxy API
  #
  # Manages IPv4-to-IPv6 proxy endpoints for making IPv6-only servers
  # accessible via IPv4. Useful for cost-effective IPv6-only VPS deployments.
  #
  # @see https://www.mythic-beasts.com/support/api/proxy
  class Proxy
    # @param client [MythicBeasts::Client] the API client
    def initialize(client)
      @client = client
    end

    # List all proxy endpoints accessible to the authenticated user
    #
    # @return [Array<Hash>] array of endpoint configurations
    # @example
    #   endpoints = client.proxy.list
    #   # => [{"domain" => "example.com", "hostname" => "www", "address" => "2a00:...", "site" => "all"}]
    def list
      response = @client.get("/proxy/endpoints")
      response["endpoints"] || response[:endpoints] || []
    end

    # List proxy endpoints for a specific domain
    #
    # @param domain [String] the domain name
    # @return [Array<Hash>] array of endpoint configurations for the domain
    # @example
    #   endpoints = client.proxy.list_for_domain("example.com")
    def list_for_domain(domain)
      response = @client.get("/proxy/endpoints/#{domain}")
      response["endpoints"] || response[:endpoints] || []
    end

    # List proxy endpoints for a specific hostname
    #
    # @param domain [String] the domain name
    # @param hostname [String] the hostname (use "@" for the domain itself)
    # @return [Array<Hash>] array of endpoint configurations
    # @example
    #   endpoints = client.proxy.list_for_hostname("example.com", "www")
    def list_for_hostname(domain, hostname)
      response = @client.get("/proxy/endpoints/#{domain}/#{hostname}")
      response["endpoints"] || response[:endpoints] || []
    end

    # Create or replace proxy endpoints for a hostname
    #
    # This replaces ALL existing endpoints for the hostname.
    #
    # @param domain [String] the domain name
    # @param hostname [String] the hostname (use "@" for the domain itself)
    # @param endpoints [Array<Hash>] array of endpoint configurations
    # @option endpoints [String] :address IPv6 address
    # @option endpoints [String] :site proxy server location or "all"
    # @option endpoints [Boolean] :proxy_protocol enable PROXY protocol (optional)
    # @return [Hash] API response
    # @example
    #   client.proxy.replace(
    #     "example.com",
    #     "www",
    #     [{address: "2a00:1098:4c4::1", site: "all"}]
    #   )
    def replace(domain, hostname, endpoints)
      @client.put("/proxy/endpoints/#{domain}/#{hostname}", body: {endpoints: endpoints})
    end

    # Add proxy endpoints for a hostname without replacing existing ones
    #
    # @param domain [String] the domain name
    # @param hostname [String] the hostname (use "@" for the domain itself)
    # @param endpoints [Array<Hash>] array of endpoint configurations
    # @option endpoints [String] :address IPv6 address
    # @option endpoints [String] :site proxy server location or "all"
    # @option endpoints [Boolean] :proxy_protocol enable PROXY protocol (optional)
    # @return [Hash] API response
    # @example
    #   client.proxy.add(
    #     "example.com",
    #     "www",
    #     [{address: "2a00:1098:4c4::1", site: "all"}]
    #   )
    def add(domain, hostname, endpoints)
      @client.post("/proxy/endpoints/#{domain}/#{hostname}", body: {endpoints: endpoints})
    end

    # Delete all proxy endpoints for a hostname
    #
    # @param domain [String] the domain name
    # @param hostname [String] the hostname
    # @return [Hash] API response
    # @example
    #   client.proxy.delete("example.com", "www")
    def delete(domain, hostname)
      @client.delete("/proxy/endpoints/#{domain}/#{hostname}")
    end

    # Delete a specific proxy endpoint
    #
    # @param domain [String] the domain name
    # @param hostname [String] the hostname
    # @param address [String] the IPv6 address
    # @param site [String] the proxy site (optional, defaults to "all")
    # @return [Hash] API response
    # @example
    #   client.proxy.delete_endpoint("example.com", "www", "2a00:1098:4c4::1")
    def delete_endpoint(domain, hostname, address, site = nil)
      path = "/proxy/endpoints/#{domain}/#{hostname}/#{address}"
      path += "/#{site}" if site
      @client.delete(path)
    end

    # List available proxy server locations
    #
    # @return [Array<String>] array of site codes (e.g., ["sov", "ams", "hex"])
    # @example
    #   sites = client.proxy.sites
    #   # => ["sov", "ams", "hex"]
    def sites
      response = @client.get("/proxy/sites")
      response["sites"] || response[:sites] || []
    end

    # Convenience method: Create a simple proxy endpoint for a server
    #
    # @param domain [String] the domain name
    # @param hostname [String] the hostname (use "@" for root domain)
    # @param ipv6_address [String] the IPv6 address of your server
    # @param proxy_protocol [Boolean] enable PROXY protocol (default: false)
    # @return [Hash] API response
    # @example
    #   # Make staging.example.com point to IPv6-only server
    #   client.proxy.create_simple(
    #     "example.com",
    #     "staging",
    #     "2a00:1098:4c4::1"
    #   )
    def create_simple(domain, hostname, ipv6_address, proxy_protocol: false)
      endpoint = {
        address: ipv6_address,
        site: "all"
      }
      endpoint[:proxy_protocol] = true if proxy_protocol

      add(domain, hostname, [endpoint])
    end
  end
end

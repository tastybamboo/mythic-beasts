module MythicBeasts
  class VPS
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # List all VPS servers
    def list
      client.get("/api/vps")
    end

    # List all VPS servers (newer endpoint)
    def servers
      client.get("/vps/servers")
    end

    # Get details of a specific VPS
    def get(server_name)
      client.get("/api/vps/#{server_name}")
    end

    # Get details of a specific VPS by identifier (newer endpoint)
    def server(identifier)
      client.get("/vps/servers/#{identifier}")
    end

    # Create a new VPS
    # Options:
    #   - product: Server product (e.g., 'VPS-1', 'VPS-2') - REQUIRED
    #   - name: Friendly name for the server
    #   - hostname: Hostname for the server
    #   - ssh_keys: SSH public key(s) for access
    #   - zone: Datacentre code (e.g., 'london', 'cambridge')
    #   - ipv4: Boolean - allocate IPv4 address (default true)
    #   - image: Operating system image name
    #   - disk_size: Disk size in MB
    #   And other optional parameters...
    def create(product:, name: nil, ssh_keys: nil, **options)
      body = {
        product: product,
        **options
      }
      body[:name] = name if name
      body[:ssh_keys] = ssh_keys if ssh_keys

      client.post("/beta/vps/servers", body: body)
    end

    # Create a new VPS with a custom identifier
    # Returns 409 Conflict if identifier already exists
    # Options are same as create method
    def create_with_identifier(identifier, product:, name: nil, ssh_keys: nil, **options)
      body = {
        product: product,
        **options
      }
      body[:name] = name if name
      body[:ssh_keys] = ssh_keys if ssh_keys

      client.post("/beta/vps/servers/#{identifier}", body: body)
    end

    # Start a VPS
    def start(server_name)
      client.post("/api/vps/#{server_name}/start")
    end

    # Stop a VPS
    def stop(server_name)
      client.post("/api/vps/#{server_name}/stop")
    end

    # Restart a VPS
    def restart(server_name)
      client.post("/api/vps/#{server_name}/restart")
    end

    # Reboot a VPS by identifier (newer endpoint)
    def reboot(identifier)
      client.post("/vps/servers/#{identifier}/reboot")
    end

    # Update a VPS (e.g., mount ISO image)
    # Options:
    #   - iso_image: ISO image name to mount
    def update(identifier, **options)
      client.patch("/vps/servers/#{identifier}", body: options)
    end

    # Delete a VPS
    def delete(server_name)
      client.delete("/api/vps/#{server_name}")
    end

    # Unprovision (permanently delete) a VPS by identifier (newer endpoint)
    def unprovision(identifier)
      client.delete("/beta/vps/servers/#{identifier}")
    end

    # Get VPS console access
    def console(server_name)
      client.get("/api/vps/#{server_name}/console")
    end

    # List available ISO images for a specific server
    # These can be mounted to the server for manual OS installation
    def iso_images(server_identifier)
      client.get("/beta/vps/servers/#{server_identifier}/iso-images")
    end

    # List available zones/datacenters for VPS provisioning
    def zones
      client.get("/beta/vps/zones")
    end

    # List available OS images for VPS provisioning
    def images
      client.get("/beta/vps/images")
    end

    # List available disk sizes
    # Returns hash with 'ssd' and 'hdd' keys containing arrays of sizes in MB
    def disk_sizes
      client.get("/beta/vps/disk-sizes")
    end

    # List available products
    def products
      client.get("/beta/vps/products")
    end
  end
end

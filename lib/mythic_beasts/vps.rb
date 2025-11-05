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

    # Get details of a specific VPS
    def get(server_name)
      client.get("/api/vps/#{server_name}")
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

    # Delete a VPS
    def delete(server_name)
      client.delete("/api/vps/#{server_name}")
    end

    # Get VPS console access
    def console(server_name)
      client.get("/api/vps/#{server_name}/console")
    end

    # List available zones/locations for VPS provisioning
    def zones
      client.get("/api/vps/zones")
    end

    # List available VPS types/plans
    def types
      client.get("/api/vps/types")
    end
  end
end

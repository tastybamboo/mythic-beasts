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
    #   - name: Server name
    #   - type: Server type (e.g., 'VPS-1', 'VPS-2')
    #   - disk: Disk size in GB
    #   - ssh_key: SSH public key for access
    def create(name:, type:, ssh_key: nil, **options)
      body = {
        name: name,
        type: type,
        **options
      }
      body[:ssh_key] = ssh_key if ssh_key

      client.post("/api/vps", body: body)
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
  end
end

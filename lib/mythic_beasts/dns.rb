module MythicBeasts
  class DNS
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # List all DNS zones
    def zones
      client.get('/dns/v2/zones')
    end

    # Get all records for a zone
    def records(zone)
      client.get("/dns/v2/zones/#{zone}/records")
    end

    # Get specific record(s) by host and type
    def get_record(zone, host, type)
      client.get("/dns/v2/zones/#{zone}/records/#{host}/#{type}")
    end

    # Create new DNS record(s)
    # records: Array of hashes with keys: host, ttl, type, data
    # Example: [{ host: 'www', ttl: 300, type: 'A', data: '1.2.3.4' }]
    def create_records(zone, records)
      client.post("/dns/v2/zones/#{zone}/records", body: { records: records })
    end

    # Replace record(s)
    def update_records(zone, records, host: nil, type: nil)
      path = "/dns/v2/zones/#{zone}/records"
      path += "/#{host}" if host
      path += "/#{type}" if type

      client.put(path, body: { records: records })
    end

    # Delete record(s)
    def delete_records(zone, host: nil, type: nil, data: nil)
      path = "/dns/v2/zones/#{zone}/records"
      path += "/#{host}" if host
      path += "/#{type}" if type

      params = data ? { data: data } : {}
      client.delete(path, params: params)
    end

    # Dynamic DNS update - updates A/AAAA record to client IP
    def dynamic_update(host)
      client.put("/dns/v2/dynamic/#{host}")
    end

    # Convenience methods for common record types
    def create_a_record(zone, host, ip, ttl: 300)
      create_records(zone, [{ host: host, ttl: ttl, type: 'A', data: ip }])
    end

    def create_aaaa_record(zone, host, ip, ttl: 300)
      create_records(zone, [{ host: host, ttl: ttl, type: 'AAAA', data: ip }])
    end

    def create_cname_record(zone, host, target, ttl: 300)
      create_records(zone, [{ host: host, ttl: ttl, type: 'CNAME', data: target }])
    end

    def create_mx_record(zone, host, priority, mail_server, ttl: 300)
      create_records(zone, [{ host: host, ttl: ttl, type: 'MX', data: "#{priority} #{mail_server}" }])
    end

    def create_txt_record(zone, host, text, ttl: 300)
      create_records(zone, [{ host: host, ttl: ttl, type: 'TXT', data: text }])
    end
  end
end

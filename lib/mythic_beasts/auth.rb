module MythicBeasts
  class Auth
    AUTH_URL = "https://auth.mythic-beasts.com/login"

    attr_reader :api_key, :api_secret

    def initialize(api_key:, api_secret:)
      @api_key = api_key
      @api_secret = api_secret
      @token = nil
      @token_expires_at = nil
    end

    def token
      return @token if @token && !token_expired?

      fetch_token
      @token
    end

    private

    def token_expired?
      return true unless @token_expires_at

      Time.now >= @token_expires_at
    end

    def fetch_token
      response = connection.post do |req|
        req.body = { grant_type: 'client_credentials' }
        req.options.timeout = 10
      end

      data = JSON.parse(response.body)
      @token = data["access_token"]
      # Expire token 30 seconds before actual expiry to be safe
      @token_expires_at = Time.now + (data["expires_in"].to_i - 30)
    rescue Faraday::Error => e
      raise AuthenticationError, "Failed to authenticate: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new(url: AUTH_URL) do |conn|
        conn.request :authorization, :basic, api_key, api_secret
        conn.request :url_encoded
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end
    end
  end
end

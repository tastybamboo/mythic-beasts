module MythicBeasts
  class Client
    API_BASE_URL = "https://api.mythic-beasts.com"

    attr_reader :auth, :dns, :vps

    def initialize(api_key:, api_secret:)
      @auth = Auth.new(api_key: api_key, api_secret: api_secret)
      @dns = DNS.new(self)
      @vps = VPS.new(self)
    end

    def get(path, params: {})
      request(:get, path, params: params)
    end

    def post(path, body: {}, params: {})
      request(:post, path, body: body, params: params)
    end

    def put(path, body: {}, params: {})
      request(:put, path, body: body, params: params)
    end

    def delete(path, params: {})
      request(:delete, path, params: params)
    end

    private

    def request(method, path, body: {}, params: {})
      response = connection.send(method) do |req|
        req.url path
        req.params = params if params.any?
        req.body = body.to_json if body.any?
      end

      JSON.parse(response.body) if response.body && !response.body.empty?
    rescue Faraday::UnauthorizedError, Faraday::ClientError => e
      if e.response&.dig(:status) == 401
        raise AuthenticationError, "Invalid credentials"
      elsif e.response&.dig(:status) == 404
        raise NotFoundError, e.message
      elsif e.response&.dig(:status) == 400
        raise ValidationError, e.message
      elsif e.response&.dig(:status) == 429
        raise RateLimitError, e.message
      else
        raise Error, e.message
      end
    rescue Faraday::ServerError => e
      raise ServerError, e.message
    end

    def connection
      @connection ||= Faraday.new(url: API_BASE_URL) do |conn|
        conn.request :authorization, :bearer, -> { auth.token }
        conn.request :json
        conn.request :retry, {
          max: 3,
          interval: 0.5,
          backoff_factor: 2,
          exceptions: [Faraday::ServerError]
        }
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end
    end
  end
end

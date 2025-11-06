require "faraday"
require "faraday/retry"
require "json"

require_relative "mythic_beasts/version"
require_relative "mythic_beasts/client"
require_relative "mythic_beasts/auth"
require_relative "mythic_beasts/dns"
require_relative "mythic_beasts/vps"
require_relative "mythic_beasts/proxy"
require_relative "mythic_beasts/errors"

module MythicBeasts
  class << self
    attr_accessor :api_key, :api_secret

    def configure
      yield self
    end

    def client
      @client ||= Client.new(api_key: api_key, api_secret: api_secret)
    end
  end
end

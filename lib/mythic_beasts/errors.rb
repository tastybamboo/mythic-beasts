module MythicBeasts
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end
  class ValidationError < Error; end
  class ConflictError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end
end

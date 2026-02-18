module NodeInfo
  # Base error class for all NodeInfo errors
  class Error < StandardError; end

  # Raised when NodeInfo discovery fails
  class DiscoveryError < Error; end

  # Raised when fetching NodeInfo document fails
  class FetchError < Error; end

  # Raised when parsing NodeInfo document fails
  class ParseError < Error; end

  # Raised when validating NodeInfo document fails
  class ValidationError < Error; end

  # Raised when HTTP request fails
  class HTTPError < Error
    attr_reader :response

    def initialize message, response = nil
      super(message)
      @response = response
    end
  end
end

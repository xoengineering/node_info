require 'http'
require 'json'

module NodeInfo
  # Client for discovering and fetching NodeInfo from Fediverse servers
  #
  # @example Fetch NodeInfo from a server
  #   client = NodeInfo::Client.new
  #   info = client.fetch("mastodon.social")
  #   puts info.software.name
  class Client
    WELL_KNOWN_PATH = '/.well-known/nodeinfo'.freeze

    SUPPORTED_SCHEMAS = [
      'http://nodeinfo.diaspora.software/ns/schema/2.1',
      'http://nodeinfo.diaspora.software/ns/schema/2.0'
    ].freeze

    attr_reader :timeout, :follow_redirects

    # Initialize a new client
    # @param timeout [Integer] HTTP timeout in seconds (default: 10)
    # @param follow_redirects [Boolean] Whether to follow HTTP redirects (default: true)
    def initialize timeout: 10, follow_redirects: true
      @timeout = timeout
      @follow_redirects = follow_redirects
    end

    # Fetch NodeInfo from a server
    # @param domain [String] The domain to fetch from (e.g., "mastodon.social")
    # @return [NodeInfo::Document]
    # @raise [NodeInfo::DiscoveryError] If discovery fails
    # @raise [NodeInfo::FetchError] If fetching fails
    # @raise [NodeInfo::ParseError] If parsing fails
    def fetch domain
      url = discover(domain)
      fetch_document(url)
    end

    # Discover NodeInfo URL for a domain
    # @param domain [String] The domain to discover
    # @return [String] The NodeInfo document URL
    # @raise [NodeInfo::DiscoveryError] If discovery fails
    def discover domain
      url = normalize_url domain, WELL_KNOWN_PATH

      response = http_client.get(url)

      raise DiscoveryError, "HTTP #{response.code}" unless response.status.success?

      links = parse_well_known response.body.to_s
      find_nodeinfo_url links
    rescue HTTP::Error => e
      raise DiscoveryError, "HTTP request failed: #{e.message}"
    end

    # Fetch NodeInfo document from URL
    # @param url [String] The NodeInfo document URL
    # @return [NodeInfo::Document]
    # @raise [NodeInfo::FetchError] If fetching fails
    def fetch_document url
      response = http_client.get url

      raise FetchError, "HTTP #{response.code}" unless response.status.success?

      Document.parse response.body.to_s
    rescue HTTP::Error => e
      raise FetchError, "HTTP request failed: #{e.message}"
    end

    private

    def http_client
      client = HTTP.timeout timeout
      client = client.follow if follow_redirects
      client
    end

    def normalize_url domain, path
      # Remove protocol if present
      domain = domain.sub %r{^https?://}, ''

      # Remove trailing slash
      domain = domain.chomp '/'

      # Add https protocol
      "https://#{domain}#{path}"
    end

    def parse_well_known body
      data = JSON.parse(body)
      links = data['links']

      raise DiscoveryError, 'No links found in well-known document' unless links
      raise DiscoveryError, 'Links must be an array' unless links.is_a?(Array)

      links
    rescue JSON::ParserError => e
      raise DiscoveryError, "Invalid JSON in well-known document: #{e.message}"
    end

    def find_nodeinfo_url links
      # Try to find a supported schema, preferring 2.1 over 2.0
      SUPPORTED_SCHEMAS.each do |schema|
        link = links.find { it['rel'] == schema }

        return link['href'] if link && link['href']
      end

      raise DiscoveryError, 'No supported NodeInfo schema found'
    end
  end
end

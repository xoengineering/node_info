require 'json'

module NodeInfo
  # Server for generating NodeInfo documents and well-known responses
  #
  # @example Basic usage
  #   server = NodeInfo::Server.new do |config|
  #     config.software_name = "myapp"
  #     config.software_version = "1.0.0"
  #     config.protocols = ["activitypub"]
  #   end
  #   server.to_json # => NodeInfo document
  #
  # @example With dynamic usage stats
  #   server = NodeInfo::Server.new do |config|
  #     config.software_name = "myapp"
  #     config.software_version = "1.0.0"
  #     config.protocols = ["activitypub"]
  #     config.usage_users = -> { User.count }
  #     config.usage_users_active_month = -> { User.active.count }
  #   end
  class Server
    # Configuration for NodeInfo server
    class Config
      attr_accessor :base_url, :metadata, :open_registrations, :protocols,
                    :services_inbound, :services_outbound,
                    :software_homepage, :software_version, :software_name, :software_repository,
                    :usage_local_comments, :usage_local_posts,
                    :usage_users, :usage_users_active_halfyear, :usage_users_active_month

      def initialize
        @metadata           = {}
        @open_registrations = false
        @protocols          = []
        @services_inbound   = []
        @services_outbound  = []
        @usage_users        = {}
      end

      # Get usage users hash, evaluating procs if necessary
      def users_hash
        users = usage_users.is_a?(Proc) ? usage_users.call : usage_users

        if users.is_a? Hash
          result = {}
          result[:total]          = evaluate_value(users[:total]) if users[:total]
          result[:activeMonth]    = evaluate_value(users[:activeMonth]    || usage_users_active_month)
          result[:activeHalfyear] = evaluate_value(users[:activeHalfyear] || usage_users_active_halfyear)
        else
          result                  = { total: evaluate_value(users) }
          result[:activeMonth]    = evaluate_value(usage_users_active_month)
          result[:activeHalfyear] = evaluate_value(usage_users_active_halfyear)
        end

        result.compact
      end

      private

      def evaluate_value value
        value.is_a?(Proc) ? value.call : value
      end
    end

    attr_reader :config

    # Initialize a new server
    # @yield [config] Configuration block
    def initialize
      @config = Config.new
      yield(config) if block_given?
      validate_config!
    end

    # Generate the well-known nodeinfo response
    # @param base_url [String] Base URL of the server (e.g., "https://example.com")
    # @return [Hash] Well-known response
    def well_known base_url = nil
      url = base_url || config.base_url
      raise ArgumentError, 'base_url is required' unless url

      {
        links: [
          {
            rel:  'http://nodeinfo.diaspora.software/ns/schema/2.1',
            href: "#{url}/nodeinfo/2.1"
          }
        ]
      }
    end

    # Generate the well-known nodeinfo response as JSON
    # @param base_url [String] Base URL of the server
    # @return [String] JSON string
    def well_known_json base_url = nil
      well_known(base_url).to_json
    end

    # Generate the NodeInfo document
    # @return [NodeInfo::Document]
    def document
      Document.new version:            '2.1',
                   software:           build_software,
                   protocols:          config.protocols,
                   services:           build_services,
                   open_registrations: config.open_registrations,
                   usage:              build_usage,
                   metadata:           config.metadata
    end

    # Generate the NodeInfo document as a hash
    # @return [Hash]
    def to_h
      document.to_h
    end

    # Generate the NodeInfo document as JSON
    # @return [String]
    def to_json(*)
      document.to_json(*)
    end

    private

    def validate_config!
      raise ValidationError, 'software_name is required'    unless config.software_name
      raise ValidationError, 'software_version is required' unless config.software_version
      raise ValidationError, 'protocols is required'        unless config.protocols
      raise ValidationError, 'protocols must be an array'   unless config.protocols.is_a?(Array)
    end

    def build_software
      Document::Software.new(
        name:       config.software_name,
        version:    config.software_version,
        repository: config.software_repository,
        homepage:   config.software_homepage
      )
    end

    def build_services
      Document::Services.new(
        inbound:  config.services_inbound,
        outbound: config.services_outbound
      )
    end

    def build_usage
      usage_hash = {
        users: config.users_hash
      }

      if config.usage_local_posts
        usage_hash[:local_posts] = if config.usage_local_posts.is_a?(Proc)
                                     config.usage_local_posts.call
                                   else
                                     config.usage_local_posts
                                   end
      end

      if config.usage_local_comments
        usage_hash[:local_comments] = if config.usage_local_comments.is_a?(Proc)
                                        config.usage_local_comments.call
                                      else
                                        config.usage_local_comments
                                      end
      end

      Document::Usage.new(**usage_hash)
    end
  end
end

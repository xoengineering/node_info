# frozen_string_literal: true

require "json"

module NodeInfo
  # Represents a NodeInfo 2.1 document
  class Document
    attr_reader :version, :software, :protocols, :services, :open_registrations,
                :usage, :metadata

    # Software information
    class Software
      attr_reader :name, :version, :repository, :homepage

      def initialize(name:, version:, repository: nil, homepage: nil)
        @name = name
        @version = version
        @repository = repository
        @homepage = homepage
      end

      def to_h
        {
          name: name,
          version: version,
          repository: repository,
          homepage: homepage
        }.compact
      end
    end

    # Services information
    class Services
      attr_reader :inbound, :outbound

      def initialize(inbound: [], outbound: [])
        @inbound = inbound
        @outbound = outbound
      end

      def to_h
        {
          inbound: inbound,
          outbound: outbound
        }
      end
    end

    # Usage statistics
    class Usage
      attr_reader :users, :local_posts, :local_comments

      def initialize(users: {}, local_posts: nil, local_comments: nil)
        @users = users
        @local_posts = local_posts
        @local_comments = local_comments
      end

      def to_h
        {
          users: users,
          localPosts: local_posts,
          localComments: local_comments
        }.compact
      end
    end

    # Parse a NodeInfo document from JSON
    # @param json [String, Hash] JSON string or hash
    # @return [NodeInfo::Document]
    def self.parse(json)
      data = json.is_a?(String) ? JSON.parse(json) : json
      data = deep_stringify_keys(data)

      metadata = data["metadata"] || {}
      metadata = metadata.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }

      new(
        version: data["version"],
        software: parse_software(data["software"]),
        protocols: data["protocols"],
        services: parse_services(data["services"]),
        open_registrations: data["openRegistrations"],
        usage: parse_usage(data["usage"]),
        metadata: metadata
      )
    rescue JSON::ParserError => e
      raise ParseError, "Invalid JSON: #{e.message}"
    rescue StandardError => e
      raise ParseError, "Failed to parse NodeInfo document: #{e.message}"
    end

    # Initialize a new NodeInfo document
    def initialize(version: "2.1", software:, protocols:, services: nil,
                   open_registrations: false, usage: nil, metadata: nil)
      @version = version
      @software = software
      @protocols = protocols
      @services = services || Services.new
      @open_registrations = open_registrations
      @usage = usage || Usage.new
      @metadata = metadata || {}

      validate!
    end

    # Convert to hash representation
    # @return [Hash]
    def to_h
      {
        version: version,
        software: software.to_h,
        protocols: protocols,
        services: services.to_h,
        openRegistrations: open_registrations,
        usage: usage.to_h,
        metadata: metadata
      }
    end

    # Convert to JSON string
    # @return [String]
    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def self.deep_stringify_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify_keys(v) }
      when Array
        obj.map { |v| deep_stringify_keys(v) }
      else
        obj
      end
    end

    def self.parse_software(data)
      return nil unless data

      Software.new(
        name: data["name"],
        version: data["version"],
        repository: data["repository"],
        homepage: data["homepage"]
      )
    end

    def self.parse_services(data)
      return Services.new unless data

      Services.new(
        inbound: data["inbound"] || [],
        outbound: data["outbound"] || []
      )
    end

    def self.parse_usage(data)
      return Usage.new unless data

      users = data["users"] || {}
      users = users.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }

      Usage.new(
        users: users,
        local_posts: data["localPosts"],
        local_comments: data["localComments"]
      )
    end

    def validate!
      raise ValidationError, "version is required" if version.nil? || version.empty?
      raise ValidationError, "software is required" if software.nil?
      raise ValidationError, "software.name is required" if software.name.nil? || software.name.empty?
      raise ValidationError, "software.version is required" if software.version.nil? || software.version.empty?
      raise ValidationError, "protocols is required" if protocols.nil?
      raise ValidationError, "protocols must be an array" unless protocols.is_a?(Array)
      raise ValidationError, "openRegistrations must be a boolean" unless [true, false].include?(open_registrations)
    end
  end
end

# frozen_string_literal: true

require_relative 'node_info/version'
require_relative 'node_info/client'
require_relative 'node_info/server'
require_relative 'node_info/document'
require_relative 'node_info/errors'

# NodeInfo protocol implementation for the Fediverse
#
# This gem provides both client and server functionality for the NodeInfo protocol
# as specified in FEP-f1d5. NodeInfo is a standardized way for Fediverse servers
# to expose metadata about themselves.
#
# @example Client usage
#   client = NodeInfo::Client.new
#   info = client.fetch("mastodon.social")
#   puts info.software.name # => "mastodon"
#
# @example Server usage
#   server = NodeInfo::Server.new do |config|
#     config.software_name = "myapp"
#     config.software_version = "1.0.0"
#     config.protocols = ["activitypub"]
#     config.open_registrations = true
#   end
#   json = server.to_json
module NodeInfo
  class << self
    # Create a new NodeInfo client
    # @return [NodeInfo::Client]
    def client
      Client.new
    end

    # Create a new NodeInfo server
    # @yield [config] Configuration block
    # @return [NodeInfo::Server]
    def server(&block)
      Server.new(&block)
    end
  end
end

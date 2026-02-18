#!/usr/bin/env ruby
# Example: Generate NodeInfo documents for your server
#
# Usage:
#   ruby examples/server_example.rb

require_relative '../lib/node_info'
require 'json'

# Create a server configuration
server = NodeInfo::Server.new do |config|
  config.software_name = 'example_fediverse_app'
  config.software_version = '1.0.0'
  config.software_repository = 'https://github.com/example/fediverse-app'
  config.software_homepage = 'https://example.com'

  config.protocols = ['activitypub']
  config.services_inbound = []
  config.services_outbound = ['atom1.0', 'rss2.0']

  config.open_registrations = true

  # Static usage stats (in production, use procs to compute dynamically)
  config.usage_users = {
    total:          1000,
    activeMonth:    500,
    activeHalfyear: 750
  }
  config.usage_local_posts = 50_000
  config.usage_local_comments = 25_000

  # Custom metadata
  config.metadata = {
    nodeName:        'Example Fediverse Instance',
    nodeDescription: 'A friendly place on the fediverse',
    maintainer:      {
      name:  'Admin User',
      email: 'admin@example.com'
    }
  }
end

puts '=== Well-Known Response (/.well-known/nodeinfo) ==='
puts JSON.pretty_generate(server.well_known('https://example.com'))
puts
puts

puts '=== NodeInfo Document (/nodeinfo/2.1) ==='
puts JSON.pretty_generate(JSON.parse(server.to_json))

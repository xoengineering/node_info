#!/usr/bin/env ruby
# Example: Fetch NodeInfo from a Fediverse server
#
# Usage:
#   ruby examples/client_example.rb mastodon.social

require_relative '../lib/node_info'

domain = ARGV[0] || 'mastodon.social'

puts "Fetching NodeInfo from #{domain}..."
puts

client = NodeInfo::Client.new

begin
  # Fetch NodeInfo
  info = client.fetch(domain)

  # Display information
  puts 'Software:'
  puts "  Name: #{info.software.name}"
  puts "  Version: #{info.software.version}"
  puts "  Repository: #{info.software.repository}" if info.software.repository
  puts "  Homepage: #{info.software.homepage}" if info.software.homepage
  puts

  puts 'Protocols:'
  info.protocols.each do |protocol|
    puts "  - #{protocol}"
  end
  puts

  puts 'Services:'
  unless info.services.inbound.empty?
    puts '  Inbound:'
    info.services.inbound.each { |s| puts "    - #{s}" }
  end
  unless info.services.outbound.empty?
    puts '  Outbound:'
    info.services.outbound.each { |s| puts "    - #{s}" }
  end
  puts

  puts "Registrations: #{info.open_registrations ? 'Open' : 'Closed'}"
  puts

  if info.usage.users && !info.usage.users.empty?
    puts 'Usage Statistics:'
    puts "  Total Users: #{info.usage.users[:total]}" if info.usage.users[:total]
    puts "  Active This Month: #{info.usage.users[:activeMonth]}" if info.usage.users[:activeMonth]
    puts "  Active Last 6 Months: #{info.usage.users[:activeHalfyear]}" if info.usage.users[:activeHalfyear]
    puts "  Local Posts: #{info.usage.local_posts}" if info.usage.local_posts
    puts "  Local Comments: #{info.usage.local_comments}" if info.usage.local_comments
    puts
  end

  unless info.metadata.empty?
    puts 'Metadata:'
    info.metadata.each do |key, value|
      puts "  #{key}: #{value}"
    end
  end
rescue NodeInfo::DiscoveryError => e
  puts 'Error: Could not discover NodeInfo endpoint'
  puts e.message
  exit 1
rescue NodeInfo::FetchError => e
  puts 'Error: Could not fetch NodeInfo document'
  puts e.message
  exit 1
rescue NodeInfo::ParseError => e
  puts 'Error: Could not parse NodeInfo document'
  puts e.message
  exit 1
rescue NodeInfo::Error => e
  puts "Error: #{e.message}"
  exit 1
end

# NodeInfo

[NodeInfo](https://nodeinfo.diaspora.software)
is a standardized way for Fediverse servers to expose metadata about themselves,
including software information, supported protocols, usage statistics, and more.

A pure Ruby implementation of the NodeInfo protocol for the Fediverse, 
providing both client and server functionality. 
This gem implements NodeInfo 2.1 as specified in 
[FEP-f1d5](https://codeberg.org/fediverse/fep/src/branch/main/fep/f1d5/fep-f1d5.md).

## Features

- Pure Ruby     - Works with any Ruby framework or plain scripts
- Client        - Discover and fetch `NodeInfo` from any Fediverse server
- Server        - Serve your own `NodeInfo` documents
- Dynamic Stats - Support for static values or dynamic procs for usage statistics

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'node_info'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install node_info
```

## Usage

### Client

Fetch NodeInfo from any Fediverse server:

```ruby
require 'node_info'

# Create a client
client = NodeInfo::Client.new

# Fetch NodeInfo from a server
info = client.fetch 'mastodon.social'

# Access the information
puts info.software.name      # => 'mastodon'
puts info.software.version   # => '4.2.0'
puts info.protocols          # => ['activitypub']
puts info.open_registrations # => true

# Access usage statistics
puts info.usage.users[:total]       # => 1000000
puts info.usage.users[:activeMonth] # => 50000
puts info.usage.local_posts         # => 5000000
```

#### Discovery and Fetching Separately

```ruby
# Discover the NodeInfo URL
url = client.discover 'mastodon.social'
# => 'https://mastodon.social/nodeinfo/2.1'

# Fetch the NodeInfo document
info = client.fetch_document url
```

#### Client Options

```ruby
# Custom timeout (default: 10 seconds)
client = NodeInfo::Client.new timeout: 5

# Disable redirect following (default: true)
client = NodeInfo::Client.new follow_redirects: false
```

### Server

Serve NodeInfo documents from your application:

```ruby
require 'node_info'

# Create a server with configuration
server = NodeInfo::Server.new do |config|
  config.software_name       = 'myapp'
  config.software_version    = '1.0.0'
  config.software_repository = 'https://github.com/example/myapp'
  config.software_homepage   = 'https://myapp.example'

  config.protocols           = ['activitypub']
  config.services_inbound    = ['atom1.0']
  config.services_outbound   = ['rss2.0', 'atom1.0']
  config.open_registrations  = true

  config.metadata = {
    nodeName:        'My Cool Instance',
    nodeDescription: 'A place for cool people'
  }
end

# Generate the well-known response (/.well-known/nodeinfo)
server.well_known_json 'https://myapp.example'
# => {
#   "links": [
#     {
#       "rel": "http://nodeinfo.diaspora.software/ns/schema/2.1",
#       "href": "https://myapp.example/nodeinfo/2.1"
#     }
#   ]
# }

# Generate the NodeInfo document (/nodeinfo/2.1)
server.to_json
# => Full NodeInfo 2.1 JSON document
```

#### Static Usage Statistics

```ruby
server = NodeInfo::Server.new do |config|
  config.software_name    = 'myapp'
  config.software_version = '1.0.0'
  config.protocols        = ['activitypub']
  
  # Static values
  config.usage_users          = { total: 100, activeMonth: 50, activeHalfyear: 75 }
  config.usage_local_posts    = 1000
  config.usage_local_comments = 500
end
```

#### Dynamic Usage Statistics

For production applications, you’ll want to compute statistics dynamically:

```ruby
server = NodeInfo::Server.new do |config|
  config.software_name    = 'myapp'
  config.software_version = '1.0.0'
  config.protocols        = ['activitypub']
  
  # Use procs to compute values dynamically
  config.usage_users                 = -> { User.count }
  config.usage_users_active_month    = -> { User.active_last_month.count }
  config.usage_users_active_halfyear = -> { User.active_last_six_months.count }
  config.usage_local_posts           = -> { Post.local.count }
  config.usage_local_comments        = -> { Comment.local.count }
end

# Stats are computed fresh each time
server.to_json  # Calls all the procs to get current values
```

#### Alternative Proc Syntax

```ruby
config.usage_users = {
  total:          -> { User.count },
  activeMonth:    -> { User.active_last_month.count },
  activeHalfyear: -> { User.active_last_six_months.count }
}
```

### Framework Integration

#### Sinatra

```ruby
require 'sinatra'
require 'node_info'

# Configure your server (perhaps in a config file or initializer)
NODE_INFO_SERVER = NodeInfo::Server.new do |config|
  config.software_name    = 'myapp'
  config.software_version = '1.0.0'
  config.protocols        = ['activitypub']
  config.base_url         = 'https://myapp.example'
  config.usage_users      = -> { User.count }
end

# Well-known endpoint
get '/.well-known/nodeinfo' do
  content_type :json
  NODE_INFO_SERVER.well_known_json
end

# NodeInfo document endpoint
get '/nodeinfo/2.1' do
  content_type :json
  NODE_INFO_SERVER.to_json
end
```

#### Rails

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get '/.well-known/nodeinfo', to: 'node_info#well_known'
  get '/nodeinfo/2.1',         to: 'node_info#show'
end

# app/controllers/node_info_controller.rb
class NodeInfoController < ApplicationController
  def well_known
    render json: server.well_known(request.base_url)
  end

  def show
    render json: server.to_json
  end

  private

  def server
    @server ||= NodeInfo::Server.new do |config|
      config.software_name            = 'myapp'
      config.software_version         = Rails.application.config.version
      config.protocols                = ['activitypub']
      config.open_registrations       = Rails.application.config.open_registrations
      config.usage_users              = -> { User.count }
      config.usage_users_active_month = -> { User.active_last_month.count }
      config.usage_local_posts        = -> { Post.local.count }
    end
  end
end
```

#### Hanami

```ruby
# config/routes.rb
get '/.well-known/nodeinfo', to: 'node_info.well_known'
get '/nodeinfo/2.1',         to: 'node_info.show'

# app/actions/node_info/well_known.rb
module MyApp
  module Actions
    module NodeInfo
      class WellKnown < MyApp::Action
        def handle request, response
          server          = build_server
          response.format = :json
          response.body   = server.well_known_json request.base_url
        end

        private

        def build_server
          NodeInfo::Server.new do |config|
            config.software_name    = 'myapp'
            config.software_version = '1.0.0'
            config.protocols        = ['activitypub']
          end
        end
      end
    end
  end
end
```

## Configuration Options

### Server Configuration

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `software_name` | String | Yes | Name of your software |
| `software_version` | String | Yes | Version of your software |
| `software_repository` | String | No | URL to source code repository |
| `software_homepage` | String | No | URL to software homepage |
| `protocols` | Array | Yes | Supported protocols (e.g., `['activitypub']`) |
| `services_inbound` | Array | No | Inbound services (e.g., `['atom1.0']`) |
| `services_outbound` | Array | No | Outbound services (e.g., `['rss2.0']`) |
| `open_registrations` | Boolean | No | Whether registrations are open (default: `false`) |
| `usage_users` | Hash/Proc | No | User statistics |
| `usage_users_active_month` | Integer/Proc | No | Active users in last month |
| `usage_users_active_halfyear` | Integer/Proc | No | Active users in last 6 months |
| `usage_local_posts` | Integer/Proc | No | Number of local posts |
| `usage_local_comments` | Integer/Proc | No | Number of local comments |
| `metadata` | Hash | No | Custom metadata |
| `base_url` | String | No | Base URL for well-known response |

## Error Handling

The gem defines several error classes:

```ruby
NodeInfo::Error           # Base error class
NodeInfo::DiscoveryError  # Discovery failed
NodeInfo::FetchError      # Fetching document failed
NodeInfo::ParseError      # Parsing document failed
NodeInfo::ValidationError # Validation failed
NodeInfo::HTTPError       # HTTP request failed
```

Example error handling:

```ruby
begin
  info = client.fetch 'example.com'
rescue NodeInfo::DiscoveryError => e
  puts "Could not discover NodeInfo: #{e.message}"
rescue NodeInfo::FetchError => e
  puts "Could not fetch NodeInfo: #{e.message}"
rescue NodeInfo::ParseError => e
  puts "Could not parse NodeInfo: #{e.message}"
rescue NodeInfo::Error => e
  puts "NodeInfo error: #{e.message}"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. 
Then, run `rake spec` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
bundle exec rspec
```

### Running RuboCop

```bash
bundle exec rubocop
```

### Running All Checks

```bash
bundle exec rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub at the https://github.com/xoengineering/node_info repo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## References

- [NodeInfo Specification](https://nodeinfo.diaspora.software/)
- [FEP-f1d5: NodeInfo in the Fediverse](https://codeberg.org/fediverse/fep/src/branch/main/fep/f1d5/fep-f1d5.md)
- [ActivityPub](https://www.w3.org/TR/activitypub/)

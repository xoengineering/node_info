# NodeInfo Gem - Quick Start Guide

## Installation & Setup

```sh
cd node_info
bundle install
```

## Running Tests

```sh
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/node_info/client_spec.rb

# Run RuboCop
bundle exec rubocop

# Run all checks
bundle exec rake
```

## Try the Examples

### Server Example

```sh
ruby examples/server_example.rb
```

This will show you:

- The well-known NodeInfo response
- A complete NodeInfo 2.1 document

### Client Example (requires network access)

```sh
ruby examples/client_example.rb mastodon.social
```

This will fetch and display NodeInfo from mastodon.social.

## Interactive Console

```sh
bin/console
```

Then try:

```ruby
# Create a client

client = NodeInfo::Client.new

# Create a server

server = NodeInfo::Server.new do |config|
  config.software_name    = 'test'
  config.software_version = '1.0.0'
  config.protocols        = ['activitypub']
end

# Generate JSON

puts server.to_json
```

## File Structure

```sh
node_info/
├── lib/
│   ├── node_info.rb         # Main module
│   └── node_info/
│       ├── version.rb       # Version constant
│       ├── errors.rb        # Error classes
│       ├── document.rb      # Document model
│       ├── client.rb        # HTTP client
│       └── server.rb        # Server/generator
├── spec/
│   ├── spec_helper.rb       # RSpec config
│   ├── integration_spec.rb  # End-to-end tests
│   └── node_info/
│       ├── document_spec.rb # Document tests
│       ├── client_spec.rb   # Client tests
│       └── server_spec.rb   # Server tests
├── examples/
│   ├── client_example.rb    # Client usage example
│   └── server_example.rb    # Server usage example
├── bin/
│   ├── setup        # Setup script
│   └── console      # Interactive console
├── README.md         # Full documentation
├── CHANGELOG.md      # Version history
├── LICENSE.txt       # MIT license
├── Gemfile           # Dependencies
├── Rakefile          # Rake tasks
├── node_info.gemspec # Gem specification
└── .rubocop.yml      # RuboCop config
```

## Key Classes

### `NodeInfo::Client`

HTTP client for fetching NodeInfo from servers.

```ruby
client = NodeInfo::Client.new
info = client.fetch 'mastodon.social'
```

### `NodeInfo::Server`

Generate NodeInfo documents for your server.

```ruby
server = NodeInfo::Server.new do |config|
  config.software_name    = 'myapp'
  config.software_version = '1.0.0'
  config.protocols        = ['activitypub']
end

server.to_json  # Returns NodeInfo JSON
```

### `NodeInfo::Document`

Represents a parsed NodeInfo document.

```ruby
doc = NodeInfo::Document.parse(json_string)
doc.software.name # => "mastodon"
doc.protocols     # => ["activitypub"]
```

## Publishing the Gem

When ready to publish:

```sh
# Build the gem
gem build node_info.gemspec

# Push to RubyGems (requires account)
gem push node_info-0.1.0.gem
```

## Next Steps

1. Read the full [README.md](README.md) for comprehensive documentation
2. Look at [examples/](examples/) for usage patterns
3. Review [spec/](spec/) to understand the test suite
4. Check out the [FEP-f1d5](https://codeberg.org/fediverse/fep/src/branch/main/fep/f1d5/fep-f1d5.md) specification

## Common Tasks

### Update Version

Edit `lib/node_info/version.rb`:

```ruby
module NodeInfo
  VERSION = '0.2.0'
end
```

### Add New Feature

1. Write tests in `spec/node_info/`
2. Implement in `lib/node_info/`
3. Update `README.md` with examples
4. Run `bundle exec rspec` and `bundle exec rubocop`
5. Update `CHANGELOG.md`

### Fix RuboCop Issues

```sh
# Auto-fix what can be fixed
bundle exec rubocop -a

# Auto-fix including unsafe corrections
bundle exec rubocop -A
```

# frozen_string_literal: true

require_relative 'lib/node_info/version'

Gem::Specification.new do |spec|
  spec.name    = 'node_info'
  spec.version = NodeInfo::VERSION
  spec.authors = ['Your Name']
  spec.email   = ['your.email@example.com']

  spec.summary     = 'NodeInfo protocol client and server implementation'
  spec.description = <<~DESCRIPTION
    A pure Ruby implementation of the NodeInfo protocol (FEP-f1d5) for the Fediverse,
    providing both client and server functionality.
  DESCRIPTION
  spec.homepage = 'https://github.com/yourusername/node_info'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 4.0.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    README.md
    LICENSE.txt
    CHANGELOG.md
  ]).reject { |f| File.directory?(f) }

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'http', '~> 5.0'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 4.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end

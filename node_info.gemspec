require_relative 'lib/node_info/version'

Gem::Specification.new do |spec|
  spec.name     = 'node_info'
  spec.version  = NodeInfo::VERSION
  spec.authors  = ['Shane Becker']
  spec.email    = ['veganstraightedge@gmail.com']
  spec.homepage = 'https://github.com/xoengineering/node_info'

  spec.summary     = 'NodeInfo protocol client and server implementation'
  spec.description = <<~DESCRIPTION
    A pure Ruby implementation of the NodeInfo protocol (FEP-f1d5) for the Fediverse,
    providing both client and server functionality.
  DESCRIPTION

  spec.license = 'MIT'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version             = '>= 4.0.0'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(
    %w[
      lib/**/*.rb
      CHANGELOG.md
      LICENSE.txt
      README.md
    ]
  ).reject { File.directory? it }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { File.basename it }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'http', '~> 5.0'
end

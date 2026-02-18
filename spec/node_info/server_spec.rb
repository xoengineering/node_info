# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NodeInfo::Server do
  describe 'initialization' do
    it 'creates a server with basic config' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
      end

      expect(server.config.software_name).to eq('myapp')
      expect(server.config.software_version).to eq('1.0.0')
      expect(server.config.protocols).to eq(['activitypub'])
    end

    it 'raises ValidationError without required fields' do
      expect do
        described_class.new do |config|
          config.software_name = 'myapp'
        end
      end.to raise_error(NodeInfo::ValidationError, /software_version is required/)
    end

    it 'validates protocols is an array' do
      expect do
        described_class.new do |config|
          config.software_name = 'myapp'
          config.software_version = '1.0.0'
          config.protocols = 'activitypub'
        end
      end.to raise_error(NodeInfo::ValidationError, /protocols must be an array/)
    end
  end

  describe '#well_known' do
    let(:server) do
      described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
      end
    end

    it 'generates well-known response with base_url parameter' do
      result = server.well_known('https://example.com')
      
      expect(result[:links]).to be_an(Array)
      expect(result[:links].first[:rel]).to eq('http://nodeinfo.diaspora.software/ns/schema/2.1')
      expect(result[:links].first[:href]).to eq('https://example.com/nodeinfo/2.1')
    end

    it 'uses config.base_url if no parameter provided' do
      server.config.base_url = 'https://configured.example'
      result = server.well_known
      
      expect(result[:links].first[:href]).to eq('https://configured.example/nodeinfo/2.1')
    end

    it 'raises ArgumentError without base_url' do
      expect { server.well_known }.to raise_error(ArgumentError, /base_url is required/)
    end
  end

  describe '#well_known_json' do
    let(:server) do
      described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.base_url = 'https://example.com'
      end
    end

    it 'generates well-known JSON' do
      json = server.well_known_json
      data = JSON.parse(json)
      
      expect(data['links']).to be_an(Array)
      expect(data['links'].first['href']).to eq('https://example.com/nodeinfo/2.1')
    end
  end

  describe '#document' do
    it 'creates a valid NodeInfo document' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.software_repository = 'https://github.com/example/myapp'
        config.software_homepage = 'https://myapp.example'
        config.protocols = ['activitypub']
        config.services_inbound = ['atom1.0']
        config.services_outbound = ['rss2.0']
        config.open_registrations = true
      end

      doc = server.document
      
      expect(doc).to be_a(NodeInfo::Document)
      expect(doc.version).to eq('2.1')
      expect(doc.software.name).to eq('myapp')
      expect(doc.software.version).to eq('1.0.0')
      expect(doc.software.repository).to eq('https://github.com/example/myapp')
      expect(doc.software.homepage).to eq('https://myapp.example')
      expect(doc.protocols).to eq(['activitypub'])
      expect(doc.services.inbound).to eq(['atom1.0'])
      expect(doc.services.outbound).to eq(['rss2.0'])
      expect(doc.open_registrations).to be true
    end

    it 'supports static usage values' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.usage_users = { total: 100, activeMonth: 50, activeHalfyear: 75 }
        config.usage_local_posts = 1000
        config.usage_local_comments = 500
      end

      doc = server.document
      
      expect(doc.usage.users[:total]).to eq(100)
      expect(doc.usage.users[:activeMonth]).to eq(50)
      expect(doc.usage.users[:activeHalfyear]).to eq(75)
      expect(doc.usage.local_posts).to eq(1000)
      expect(doc.usage.local_comments).to eq(500)
    end

    it 'supports dynamic usage values with procs' do
      user_count = 100
      active_count = 50
      
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.usage_users = -> { user_count }
        config.usage_users_active_month = -> { active_count }
        config.usage_local_posts = -> { 1000 }
      end

      doc = server.document
      
      expect(doc.usage.users[:total]).to eq(100)
      expect(doc.usage.users[:activeMonth]).to eq(50)
      expect(doc.usage.local_posts).to eq(1000)

      # Values are dynamic
      user_count = 200
      active_count = 100
      
      doc2 = server.document
      expect(doc2.usage.users[:total]).to eq(200)
      expect(doc2.usage.users[:activeMonth]).to eq(100)
    end

    it 'supports hash with procs for users' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.usage_users = {
          total: -> { 100 },
          activeMonth: -> { 50 }
        }
      end

      doc = server.document
      
      expect(doc.usage.users[:total]).to eq(100)
      expect(doc.usage.users[:activeMonth]).to eq(50)
    end

    it 'includes custom metadata' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.metadata = {
          nodeName: 'My Cool Instance',
          nodeDescription: 'A place for cool people'
        }
      end

      doc = server.document
      
      expect(doc.metadata[:nodeName]).to eq('My Cool Instance')
      expect(doc.metadata[:nodeDescription]).to eq('A place for cool people')
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
      end

      hash = server.to_h
      
      expect(hash[:version]).to eq('2.1')
      expect(hash[:software][:name]).to eq('myapp')
      expect(hash[:protocols]).to eq(['activitypub'])
    end
  end

  describe '#to_json' do
    it 'converts to JSON' do
      server = described_class.new do |config|
        config.software_name = 'myapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.open_registrations = true
      end

      json = server.to_json
      data = JSON.parse(json)
      
      expect(data['version']).to eq('2.1')
      expect(data['software']['name']).to eq('myapp')
      expect(data['software']['version']).to eq('1.0.0')
      expect(data['protocols']).to eq(['activitypub'])
      expect(data['openRegistrations']).to be true
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NodeInfo::Document do
  let(:valid_data) do
    {
      version: '2.1',
      software: {
        name: 'mastodon',
        version: '4.2.0',
        repository: 'https://github.com/mastodon/mastodon',
        homepage: 'https://joinmastodon.org'
      },
      protocols: ['activitypub'],
      services: {
        inbound: [],
        outbound: []
      },
      openRegistrations: true,
      usage: {
        users: {
          total: 1000,
          activeMonth: 500,
          activeHalfyear: 750
        },
        localPosts: 10000,
        localComments: 5000
      },
      metadata: {
        nodeName: 'My Instance'
      }
    }
  end

  describe '.parse' do
    it 'parses valid JSON string' do
      json = valid_data.to_json
      doc = described_class.parse(json)

      expect(doc.version).to eq('2.1')
      expect(doc.software.name).to eq('mastodon')
      expect(doc.software.version).to eq('4.2.0')
      expect(doc.protocols).to eq(['activitypub'])
      expect(doc.open_registrations).to be true
    end

    it 'parses valid hash' do
      doc = described_class.parse(valid_data)

      expect(doc.version).to eq('2.1')
      expect(doc.software.name).to eq('mastodon')
    end

    it 'raises ParseError for invalid JSON' do
      expect { described_class.parse('invalid json') }.to raise_error(NodeInfo::ParseError)
    end

    it 'parses minimal document' do
      minimal = {
        version: '2.1',
        software: { name: 'test', version: '1.0' },
        protocols: ['activitypub'],
        services: { inbound: [], outbound: [] },
        openRegistrations: false,
        usage: { users: {} },
        metadata: {}
      }

      doc = described_class.parse(minimal)
      expect(doc.software.name).to eq('test')
    end
  end

  describe '#initialize' do
    it 'creates a valid document' do
      software = NodeInfo::Document::Software.new(
        name: 'test',
        version: '1.0.0'
      )

      doc = described_class.new(
        software: software,
        protocols: ['activitypub']
      )

      expect(doc.version).to eq('2.1')
      expect(doc.software.name).to eq('test')
      expect(doc.protocols).to eq(['activitypub'])
      expect(doc.open_registrations).to be false
    end

    it 'validates required fields' do
      expect do
        described_class.new(software: nil, protocols: [])
      end.to raise_error(NodeInfo::ValidationError, /software is required/)
    end

    it 'validates software.name' do
      software = NodeInfo::Document::Software.new(name: '', version: '1.0')
      
      expect do
        described_class.new(software: software, protocols: [])
      end.to raise_error(NodeInfo::ValidationError, /software.name is required/)
    end

    it 'validates protocols is an array' do
      software = NodeInfo::Document::Software.new(name: 'test', version: '1.0')
      
      expect do
        described_class.new(software: software, protocols: 'activitypub')
      end.to raise_error(NodeInfo::ValidationError, /protocols must be an array/)
    end

    it 'validates openRegistrations is a boolean' do
      software = NodeInfo::Document::Software.new(name: 'test', version: '1.0')
      
      expect do
        described_class.new(
          software: software,
          protocols: [],
          open_registrations: 'yes'
        )
      end.to raise_error(NodeInfo::ValidationError, /openRegistrations must be a boolean/)
    end
  end

  describe '#to_h' do
    it 'converts to hash with camelCase keys' do
      doc = described_class.parse(valid_data)
      hash = doc.to_h

      expect(hash[:version]).to eq('2.1')
      expect(hash[:software][:name]).to eq('mastodon')
      expect(hash[:openRegistrations]).to be true
      expect(hash[:usage][:localPosts]).to eq(10000)
    end
  end

  describe '#to_json' do
    it 'converts to JSON string' do
      doc = described_class.parse(valid_data)
      json_string = doc.to_json

      parsed = JSON.parse(json_string)
      expect(parsed['version']).to eq('2.1')
      expect(parsed['software']['name']).to eq('mastodon')
    end
  end

  describe NodeInfo::Document::Software do
    it 'creates software info with required fields' do
      software = described_class.new(name: 'test', version: '1.0.0')
      
      expect(software.name).to eq('test')
      expect(software.version).to eq('1.0.0')
      expect(software.repository).to be_nil
      expect(software.homepage).to be_nil
    end

    it 'creates software info with all fields' do
      software = described_class.new(
        name: 'test',
        version: '1.0.0',
        repository: 'https://github.com/test/test',
        homepage: 'https://test.example'
      )
      
      expect(software.repository).to eq('https://github.com/test/test')
      expect(software.homepage).to eq('https://test.example')
    end

    it 'converts to hash' do
      software = described_class.new(
        name: 'test',
        version: '1.0.0',
        repository: 'https://github.com/test/test'
      )
      
      hash = software.to_h
      expect(hash[:name]).to eq('test')
      expect(hash[:version]).to eq('1.0.0')
      expect(hash[:repository]).to eq('https://github.com/test/test')
      expect(hash).not_to have_key(:homepage)
    end
  end

  describe NodeInfo::Document::Services do
    it 'creates empty services' do
      services = described_class.new
      
      expect(services.inbound).to eq([])
      expect(services.outbound).to eq([])
    end

    it 'creates services with values' do
      services = described_class.new(
        inbound: ['atom1.0'],
        outbound: ['atom1.0', 'rss2.0']
      )
      
      expect(services.inbound).to eq(['atom1.0'])
      expect(services.outbound).to eq(['atom1.0', 'rss2.0'])
    end
  end

  describe NodeInfo::Document::Usage do
    it 'creates empty usage' do
      usage = described_class.new
      
      expect(usage.users).to eq({})
      expect(usage.local_posts).to be_nil
      expect(usage.local_comments).to be_nil
    end

    it 'creates usage with values' do
      usage = described_class.new(
        users: { total: 100, activeMonth: 50 },
        local_posts: 1000,
        local_comments: 500
      )
      
      expect(usage.users[:total]).to eq(100)
      expect(usage.local_posts).to eq(1000)
    end
  end
end

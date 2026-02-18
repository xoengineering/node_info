require 'spec_helper'

RSpec.describe 'NodeInfo integration' do
  describe 'complete client/server workflow' do
    let(:base_url) { 'https://example.com' }
    let(:well_known_url) { "#{base_url}/.well-known/nodeinfo" }
    let(:nodeinfo_url) { "#{base_url}/nodeinfo/2.1" }

    it 'creates server, serves documents, and client can fetch them' do
      # Step 1: Create a server
      server = NodeInfo::Server.new do |config|
        config.software_name = 'testapp'
        config.software_version = '2.0.0'
        config.software_repository = 'https://github.com/test/testapp'
        config.protocols = ['activitypub']
        config.open_registrations = true
        config.usage_users = { total: 100, activeMonth: 50 }
        config.usage_local_posts = 1000
        config.metadata = { nodeName: 'Test Instance' }
      end

      # Step 2: Generate well-known response
      well_known_json = server.well_known_json(base_url)
      well_known_data = JSON.parse(well_known_json)

      expect(well_known_data['links']).to be_an(Array)
      expect(well_known_data['links'].first['rel']).to eq('http://nodeinfo.diaspora.software/ns/schema/2.1')
      expect(well_known_data['links'].first['href']).to eq(nodeinfo_url)

      # Step 3: Generate NodeInfo document
      nodeinfo_json = server.to_json
      nodeinfo_data = JSON.parse(nodeinfo_json)

      expect(nodeinfo_data['version']).to eq('2.1')
      expect(nodeinfo_data['software']['name']).to eq('testapp')
      expect(nodeinfo_data['software']['version']).to eq('2.0.0')
      expect(nodeinfo_data['protocols']).to eq(['activitypub'])
      expect(nodeinfo_data['openRegistrations']).to be true
      expect(nodeinfo_data['usage']['users']['total']).to eq(100)

      # Step 4: Mock HTTP responses
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_json)
      stub_request(:get, nodeinfo_url)
        .to_return(status: 200, body: nodeinfo_json)

      # Step 5: Client fetches the data
      client = NodeInfo::Client.new

      # Discover NodeInfo URL
      discovered_url = client.discover('example.com')
      expect(discovered_url).to eq(nodeinfo_url)

      # Fetch the document
      info = client.fetch('example.com')

      # Step 6: Verify client parsed everything correctly
      expect(info).to be_a(NodeInfo::Document)
      expect(info.software.name).to eq('testapp')
      expect(info.software.version).to eq('2.0.0')
      expect(info.software.repository).to eq('https://github.com/test/testapp')
      expect(info.protocols).to eq(['activitypub'])
      expect(info.open_registrations).to be true
      expect(info.usage.users[:total]).to eq(100)
      expect(info.usage.users[:activeMonth]).to eq(50)
      expect(info.usage.local_posts).to eq(1000)
      expect(info.metadata[:nodeName]).to eq('Test Instance')
    end
  end

  describe 'dynamic statistics' do
    it 'evaluates procs when generating document' do
      user_count = 100
      post_count = 1000

      server = NodeInfo::Server.new do |config|
        config.software_name = 'testapp'
        config.software_version = '1.0.0'
        config.protocols = ['activitypub']
        config.usage_users = -> { user_count }
        config.usage_local_posts = -> { post_count }
      end

      # First generation
      doc1 = server.document
      expect(doc1.usage.users[:total]).to eq(100)
      expect(doc1.usage.local_posts).to eq(1000)

      # Change values
      user_count = 200
      post_count = 2000

      # Second generation should use new values
      doc2 = server.document
      expect(doc2.usage.users[:total]).to eq(200)
      expect(doc2.usage.local_posts).to eq(2000)
    end
  end

  describe 'module convenience methods' do
    it 'provides NodeInfo.client' do
      client = NodeInfo.client
      expect(client).to be_a(NodeInfo::Client)
    end

    it 'provides NodeInfo.server' do
      server = NodeInfo.server do |config|
        config.software_name = 'test'
        config.software_version = '1.0'
        config.protocols = []
      end
      expect(server).to be_a(NodeInfo::Server)
    end
  end

  describe 'error scenarios' do
    it 'handles missing well-known endpoint' do
      stub_request(:get, 'https://missing.example/.well-known/nodeinfo')
        .to_return(status: 404)

      client = NodeInfo::Client.new
      expect { client.fetch('missing.example') }.to raise_error(NodeInfo::DiscoveryError)
    end

    it 'handles invalid NodeInfo document' do
      well_known = {
        links: [{
          rel:  'http://nodeinfo.diaspora.software/ns/schema/2.1',
          href: 'https://invalid.example/nodeinfo/2.1'
        }]
      }.to_json

      stub_request(:get, 'https://invalid.example/.well-known/nodeinfo')
        .to_return(status: 200, body: well_known)
      stub_request(:get, 'https://invalid.example/nodeinfo/2.1')
        .to_return(status: 200, body: 'invalid json')

      client = NodeInfo::Client.new
      expect { client.fetch('invalid.example') }.to raise_error(NodeInfo::ParseError)
    end

    it 'handles server validation errors' do
      expect do
        NodeInfo::Server.new do |config|
          config.software_name = 'test'
          # Missing version and protocols
        end
      end.to raise_error(NodeInfo::ValidationError)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe NodeInfo::Client do
  let(:client) { described_class.new }
  let(:domain) { "mastodon.social" }
  let(:well_known_url) { "https://mastodon.social/.well-known/nodeinfo" }
  let(:nodeinfo_url) { "https://mastodon.social/nodeinfo/2.1" }

  let(:well_known_response) do
    {
      links: [
        {
          rel: "http://nodeinfo.diaspora.software/ns/schema/2.1",
          href: nodeinfo_url
        }
      ]
    }.to_json
  end

  let(:nodeinfo_response) do
    {
      version: "2.1",
      software: {
        name: "mastodon",
        version: "4.2.0"
      },
      protocols: ["activitypub"],
      services: {
        inbound: [],
        outbound: []
      },
      openRegistrations: true,
      usage: {
        users: {
          total: 1000
        }
      },
      metadata: {}
    }.to_json
  end

  describe "#discover" do
    it "discovers NodeInfo URL" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_response)

      url = client.discover(domain)
      expect(url).to eq(nodeinfo_url)
    end

    it "handles domain with https protocol" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_response)

      url = client.discover("https://#{domain}")
      expect(url).to eq(nodeinfo_url)
    end

    it "handles domain with trailing slash" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_response)

      url = client.discover("#{domain}/")
      expect(url).to eq(nodeinfo_url)
    end

    it "prefers 2.1 schema over 2.0" do
      response = {
        links: [
          {
            rel: "http://nodeinfo.diaspora.software/ns/schema/2.0",
            href: "https://mastodon.social/nodeinfo/2.0"
          },
          {
            rel: "http://nodeinfo.diaspora.software/ns/schema/2.1",
            href: nodeinfo_url
          }
        ]
      }.to_json

      stub_request(:get, well_known_url)
        .to_return(status: 200, body: response)

      url = client.discover(domain)
      expect(url).to eq(nodeinfo_url)
    end

    it "falls back to 2.0 if 2.1 not available" do
      response = {
        links: [
          {
            rel: "http://nodeinfo.diaspora.software/ns/schema/2.0",
            href: "https://mastodon.social/nodeinfo/2.0"
          }
        ]
      }.to_json

      stub_request(:get, well_known_url)
        .to_return(status: 200, body: response)

      url = client.discover(domain)
      expect(url).to eq("https://mastodon.social/nodeinfo/2.0")
    end

    it "raises DiscoveryError on HTTP error" do
      stub_request(:get, well_known_url)
        .to_return(status: 404)

      expect { client.discover(domain) }.to raise_error(NodeInfo::DiscoveryError, /HTTP 404/)
    end

    it "raises DiscoveryError on invalid JSON" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: "invalid json")

      expect { client.discover(domain) }.to raise_error(NodeInfo::DiscoveryError, /Invalid JSON/)
    end

    it "raises DiscoveryError when no links found" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: "{}".to_json)

      expect { client.discover(domain) }.to raise_error(NodeInfo::DiscoveryError, /No links found/)
    end

    it "raises DiscoveryError when no supported schema found" do
      response = {
        links: [
          {
            rel: "http://nodeinfo.diaspora.software/ns/schema/1.0",
            href: "https://mastodon.social/nodeinfo/1.0"
          }
        ]
      }.to_json

      stub_request(:get, well_known_url)
        .to_return(status: 200, body: response)

      expect { client.discover(domain) }.to raise_error(NodeInfo::DiscoveryError, /No supported NodeInfo schema/)
    end
  end

  describe "#fetch_document" do
    it "fetches and parses NodeInfo document" do
      stub_request(:get, nodeinfo_url)
        .to_return(status: 200, body: nodeinfo_response)

      doc = client.fetch_document(nodeinfo_url)
      
      expect(doc).to be_a(NodeInfo::Document)
      expect(doc.software.name).to eq("mastodon")
      expect(doc.software.version).to eq("4.2.0")
      expect(doc.protocols).to eq(["activitypub"])
    end

    it "raises FetchError on HTTP error" do
      stub_request(:get, nodeinfo_url)
        .to_return(status: 500)

      expect { client.fetch_document(nodeinfo_url) }.to raise_error(NodeInfo::FetchError, /HTTP 500/)
    end

    it "raises ParseError on invalid JSON" do
      stub_request(:get, nodeinfo_url)
        .to_return(status: 200, body: "invalid json")

      expect { client.fetch_document(nodeinfo_url) }.to raise_error(NodeInfo::ParseError)
    end
  end

  describe "#fetch" do
    it "discovers and fetches NodeInfo in one call" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_response)
      stub_request(:get, nodeinfo_url)
        .to_return(status: 200, body: nodeinfo_response)

      doc = client.fetch(domain)
      
      expect(doc).to be_a(NodeInfo::Document)
      expect(doc.software.name).to eq("mastodon")
    end

    it "propagates discovery errors" do
      stub_request(:get, well_known_url)
        .to_return(status: 404)

      expect { client.fetch(domain) }.to raise_error(NodeInfo::DiscoveryError)
    end

    it "propagates fetch errors" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_response)
      stub_request(:get, nodeinfo_url)
        .to_return(status: 500)

      expect { client.fetch(domain) }.to raise_error(NodeInfo::FetchError)
    end
  end

  describe "initialization options" do
    it "accepts custom timeout" do
      client = described_class.new(timeout: 5)
      expect(client.timeout).to eq(5)
    end

    it "accepts follow_redirects option" do
      client = described_class.new(follow_redirects: false)
      expect(client.follow_redirects).to be false
    end
  end
end

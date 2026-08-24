require "rails_helper"

RSpec.describe Providers::Youtube::Client do
  it "requests offline access and maps channels returned for the authenticated account" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post(%r{/token}) do
        [200, {}, {access_token: "access", refresh_token: "refresh", expires_in: 3600, scope: Providers::Youtube::Client::SCOPE}.to_json]
      end
      stub.get(%r{/youtube/v3/channels}) do |env|
        expect(env.params).to include("mine" => "true", "part" => "snippet")
        [200, {}, {items: [{id: "youtube-1", snippet: {title: "Pulse Creator", customUrl: "@pulse", thumbnails: {default: {url: "https://example.com/avatar.png"}}}}]}.to_json]
      end
    end
    client = build_client(stubs)
    channel = build(:channel, provider: :youtube)
    authorization_params = CGI.parse(URI.parse(client.authorization_url(state: "state", channel:)).query)

    token_set = client.exchange_code(code: "code")
    candidates = client.discover_accounts(token_set:, channel:)

    expect(authorization_params).to include("access_type" => ["offline"], "include_granted_scopes" => ["true"])
    expect(candidates.first).to have_attributes(provider_account_id: "youtube-1", name: "Pulse Creator", handle: "@pulse")
    stubs.verify_stubbed_calls
  end

  it "preserves the refresh token when Google only rotates the access token" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post(%r{/token}) { [200, {}, {access_token: "new-access", expires_in: 3600}.to_json] }
    end
    refreshed = build_client(stubs).refresh(
      token_set: Providers::TokenSet.new(
        access_token: "old-access",
        refresh_token: "old-refresh",
        expires_at: Time.current,
        scopes: [Providers::Youtube::Client::SCOPE],
        provider_identity_id: nil,
        metadata: {}
      )
    )

    expect(refreshed).to have_attributes(access_token: "new-access", refresh_token: "old-refresh")
  end

  private

  def build_client(stubs)
    connection = Faraday.new { |faraday| faraday.adapter :test, stubs }
    config = Providers::Configuration::Config.new(
      client_id: "youtube-client",
      client_secret: "youtube-secret",
      app_host: "https://pulse.test",
      api_version: nil
    )
    described_class.new(config:, callback_url: "https://pulse.test/oauth/provider-connections/youtube/callback", connection:)
  end
end

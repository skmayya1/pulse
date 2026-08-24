require "rails_helper"

RSpec.describe Providers::Tiktok::Client do
  it "exchanges a code and discovers the TikTok account" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post(%r{/v2/oauth/token/}) do |env|
        expect(env.body).to include("grant_type=authorization_code", "code=code")
        [200, {}, {
          access_token: "access",
          refresh_token: "refresh",
          expires_in: 3600,
          refresh_expires_in: 31_536_000,
          open_id: "open-1",
          scope: "user.info.basic"
        }.to_json]
      end
      stub.get(%r{/v2/user/info/}) do |env|
        expect(env.request_headers.fetch("Authorization")).to eq("Bearer access")
        [200, {}, {data: {user: {open_id: "open-1", union_id: "union-1", display_name: "Creator", avatar_url: "https://example.com/avatar.png"}}, error: {code: "ok"}}.to_json]
      end
    end
    client = build_client(stubs)

    token_set = client.exchange_code(code: "code")
    candidates = client.discover_accounts(token_set:, channel: build(:channel, provider: :tiktok))

    expect(token_set).to have_attributes(access_token: "access", refresh_token: "refresh", provider_identity_id: "open-1")
    expect(candidates.first).to have_attributes(provider_account_id: "open-1", provider_identity_id: "union-1", name: "Creator")
    stubs.verify_stubbed_calls
  end

  private

  def build_client(stubs)
    connection = Faraday.new { |faraday| faraday.adapter :test, stubs }
    config = Providers::Configuration::Config.new(
      client_id: "tiktok-key",
      client_secret: "tiktok-secret",
      app_host: "https://pulse.test",
      api_version: nil
    )
    described_class.new(config:, callback_url: "https://pulse.test/oauth/provider-connections/tiktok/callback", connection:)
  end
end

require "rails_helper"

RSpec.describe Providers::Meta::Client do
  it "exchanges codes without placing secrets or tokens in request URLs" do
    client, stubs = build_client do |stub|
      stub.post(%r{/oauth/access_token}) do |env|
        expect(env.url.query).to be_nil
        expect(env.body).to include("client_secret=meta-secret", "code=code")
        [200, {}, {access_token: "user-token", expires_in: 3600}.to_json]
      end
      stub.get(%r{/me}) do |env|
        expect(env.url.query).to eq("fields=id")
        expect(env.request_headers.fetch("Authorization")).to eq("Bearer user-token")
        [200, {}, {id: "meta-user"}.to_json]
      end
    end

    result = client.exchange_code(code: "code")

    expect(result).to have_attributes(access_token: "user-token", provider_identity_id: "meta-user")
    stubs.verify_stubbed_calls
  end

  it "requests discovery scopes and maps an Instagram professional account" do
    client, stubs = build_client do |stub|
      stub.get(%r{/me/accounts}) do
        expect(_1.request_headers.fetch("Authorization")).to eq("Bearer user-token")
        [200, {}, {
          data: [{
            id: "page-1",
            name: "Page",
            access_token: "page-token",
            instagram_business_account: {
              id: "instagram-1",
              username: "creator",
              name: "Creator",
              profile_picture_url: "https://example.com/avatar.png"
            }
          }]
        }.to_json]
      end
    end
    channel = build(:channel, key: "instagram", provider: :meta)
    authorization_url = URI.parse(client.authorization_url(state: "state", channel:))

    candidates = client.discover_accounts(token_set: token_set, channel:)

    expect(CGI.parse(authorization_url.query).fetch("scope").first).to include("pages_show_list", "instagram_basic")
    expect(candidates.first).to have_attributes(
      provider_account_id: "instagram-1",
      provider_identity_id: "meta-user",
      handle: "creator",
      access_token: "page-token"
    )
    stubs.verify_stubbed_calls
  end

  private

  def build_client(&block)
    stubs = Faraday::Adapter::Test::Stubs.new(&block)
    connection = Faraday.new { |faraday| faraday.adapter :test, stubs }
    config = Providers::Configuration::Config.new(
      client_id: "meta-client",
      client_secret: "meta-secret",
      app_host: "https://pulse.test",
      api_version: "v24.0"
    )
    [described_class.new(config:, callback_url: "https://pulse.test/oauth/provider-connections/meta/callback", connection:), stubs]
  end

  def token_set
    Providers::TokenSet.new(
      access_token: "user-token",
      refresh_token: nil,
      expires_at: 1.hour.from_now,
      scopes: %w[pages_show_list instagram_basic],
      provider_identity_id: "meta-user",
      metadata: {}
    )
  end
end

require "rails_helper"

RSpec.describe Providers::Meta::Client do
  it "exchanges codes for a long-lived token without placing secrets in request URLs" do
    client, stubs = build_client do |stub|
      stub.post(%r{/oauth/access_token}) do |env|
        expect(env.url.query).to be_nil
        expect(env.body).to include("client_secret=meta-secret", "code=code")
        [200, {}, {access_token: "short-token", expires_in: 3600}.to_json]
      end
      stub.post(%r{/oauth/access_token}) do |env|
        expect(env.url.query).to be_nil
        expect(env.body).to include("grant_type=fb_exchange_token", "fb_exchange_token=short-token")
        [200, {}, {access_token: "long-token", expires_in: 5_184_000}.to_json]
      end
      stub.get(%r{/me$}) do |env|
        expect(env.url.query).to eq("fields=id")
        expect(env.request_headers.fetch("Authorization")).to eq("Bearer long-token")
        [200, {}, {id: "meta-user"}.to_json]
      end
    end

    result = client.exchange_code(code: "code")

    expect(result).to have_attributes(access_token: "long-token", provider_identity_id: "meta-user")
    stubs.verify_stubbed_calls
  end

  it "uses a Login for Business configuration and maps Facebook Pages" do
    client, stubs = build_client do |stub|
      stub.get(%r{/me/accounts}) do
        expect(_1.request_headers.fetch("Authorization")).to eq("Bearer user-token")
        [200, {}, {
          data: [{
            id: "page-1",
            name: "Page",
            access_token: "page-token",
            picture: {data: {url: "https://example.com/page.png"}}
          }]
        }.to_json]
      end
    end
    channel = build(:channel, key: "facebook", provider: :meta)
    authorization_url = URI.parse(client.authorization_url(state: "state", channel:))
    query = CGI.parse(authorization_url.query)

    candidates = client.discover_accounts(token_set:, channel:)

    expect(authorization_url.to_s).to start_with("https://www.facebook.com/v24.0/dialog/oauth")
    expect(query).to include("config_id" => ["meta-config"], "client_id" => ["meta-client"])
    expect(query).not_to have_key("scope")
    expect(candidates.first).to have_attributes(
      provider_account_id: "page-1",
      provider_identity_id: "meta-user",
      name: "Page",
      access_token: "page-token",
      expires_at: nil
    )
    stubs.verify_stubbed_calls
  end

  it "requires a Facebook Login for Business configuration id" do
    expect {
      described_class.new(
        config: Providers::Configuration::Config.new(
          client_id: "meta-client",
          client_secret: "meta-secret",
          app_host: "https://pulse.test",
          api_version: "v24.0"
        ),
        callback_url: "https://pulse.test/oauth/provider-connections/meta/callback"
      )
    }.to raise_error(Providers::ConfigurationError)
  end

  private

  def build_client(&block)
    stubs = Faraday::Adapter::Test::Stubs.new(&block)
    connection = Faraday.new { |faraday| faraday.adapter :test, stubs }
    config = Providers::Configuration::Config.new(
      client_id: "meta-client",
      client_secret: "meta-secret",
      app_host: "https://pulse.test",
      api_version: "v24.0",
      config_id: "meta-config"
    )
    [described_class.new(config:, callback_url: "https://pulse.test/oauth/provider-connections/meta/callback", connection:), stubs]
  end

  def token_set
    Providers::TokenSet.new(
      access_token: "user-token",
      refresh_token: nil,
      expires_at: 1.hour.from_now,
      scopes: [],
      provider_identity_id: "meta-user",
      metadata: {}
    )
  end
end

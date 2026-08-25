require "rails_helper"

RSpec.describe Providers::Instagram::Client do
  it "authorizes through Instagram Login and maps the professional account" do
    client, stubs = build_client do |stub|
      stub.post(%r{/oauth/access_token}) do |env|
        expect(env.url.to_s).to start_with("https://api.instagram.com/oauth/access_token")
        expect(env.url.query).to be_nil
        expect(env.body).to include("client_secret=instagram-secret", "code=code", "grant_type=authorization_code")
        [200, {}, {
          data: [{
            access_token: "short-token",
            user_id: "instagram-1",
            permissions: "instagram_business_basic,instagram_business_content_publish"
          }]
        }.to_json]
      end
      stub.get(%r{/access_token}) do |env|
        expect(env.url.query).to include("grant_type=ig_exchange_token", "access_token=short-token")
        [200, {}, {access_token: "long-token", token_type: "bearer", expires_in: 5_184_000}.to_json]
      end
      stub.get(%r{/me}) do |env|
        expect(CGI.parse(env.url.query)).to include(
          "fields" => ["user_id,username,name,account_type,profile_picture_url"]
        )
        expect(env.request_headers.fetch("Authorization")).to eq("Bearer long-token")
        [200, {}, {
          user_id: "instagram-1",
          username: "creator",
          name: "Creator",
          account_type: "BUSINESS",
          profile_picture_url: "https://example.com/avatar.png"
        }.to_json]
      end
    end
    channel = build(:channel, key: "instagram", provider: :instagram)
    authorization_url = URI.parse(client.authorization_url(state: "state", channel:))
    query = CGI.parse(authorization_url.query)

    token_set = client.exchange_code(code: "code")
    candidates = client.discover_accounts(token_set:, channel:)

    expect(authorization_url.to_s).to start_with("https://www.instagram.com/oauth/authorize")
    expect(query.fetch("scope").first).to include(
      "instagram_business_basic",
      "instagram_business_content_publish",
      "instagram_business_manage_comments",
      "instagram_business_manage_messages"
    )
    expect(query).to include("enable_fb_login" => ["false"], "client_id" => ["instagram-client"])
    expect(token_set).to have_attributes(access_token: "long-token", provider_identity_id: "instagram-1")
    expect(candidates.first).to have_attributes(
      provider_account_id: "instagram-1",
      handle: "creator",
      name: "Creator",
      access_token: "long-token"
    )
    stubs.verify_stubbed_calls
  end

  it "refreshes a long-lived Instagram user token" do
    client, stubs = build_client do |stub|
      stub.get(%r{/refresh_access_token}) do |env|
        expect(env.url.query).to include("grant_type=ig_refresh_token", "access_token=old-token")
        [200, {}, {access_token: "new-token", token_type: "bearer", expires_in: 5_184_000}.to_json]
      end
    end

    refreshed = client.refresh(token_set: token_set)

    expect(refreshed).to have_attributes(access_token: "new-token", provider_identity_id: "instagram-1")
    stubs.verify_stubbed_calls
  end

  private

  def build_client(&block)
    stubs = Faraday::Adapter::Test::Stubs.new(&block)
    connection = Faraday.new { |faraday| faraday.adapter :test, stubs }
    config = Providers::Configuration::Config.new(
      client_id: "instagram-client",
      client_secret: "instagram-secret",
      app_host: "https://pulse.test"
    )
    [described_class.new(config:, callback_url: "https://pulse.test/oauth/provider-connections/instagram/callback", connection:), stubs]
  end

  def token_set
    Providers::TokenSet.new(
      access_token: "old-token",
      refresh_token: nil,
      expires_at: 1.day.from_now,
      scopes: Providers::Instagram::Client::SCOPES,
      provider_identity_id: "instagram-1",
      metadata: {}
    )
  end
end

require "rails_helper"

RSpec.describe "Provider connections" do
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
  end

  it "starts Instagram OAuth through Instagram Login without exposing secrets" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel, key: "instagram", provider: :instagram)
    sign_in(membership.user)

    with_provider_environment do
      post settings_organization_channel_provider_connections_path(channel.key)
    end

    query = CGI.parse(URI.parse(response.location).query)
    expect(response).to redirect_to(%r{\Ahttps://www.instagram.com/oauth/authorize})
    expect(query).to include("state", "client_id" => ["instagram-client"], "enable_fb_login" => ["false"])
    expect(query.fetch("scope").first).to include("instagram_business_basic")
    expect(response.location).not_to include("instagram-secret")
  end

  it "starts Facebook OAuth through Facebook Login for Business without exposing secrets" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel, key: "facebook", provider: :meta)
    sign_in(membership.user)

    with_provider_environment do
      post settings_organization_channel_provider_connections_path(channel.key)
    end

    query = CGI.parse(URI.parse(response.location).query)
    expect(response).to redirect_to(%r{\Ahttps://www.facebook.com/})
    expect(query).to include("state", "client_id" => ["meta-client"], "config_id" => ["meta-config"])
    expect(query).not_to have_key("scope")
    expect(response.location).not_to include("meta-secret")
  end

  it "completes a callback and creates the discovered account" do
    membership = create(:organization_membership, role: :owner)
    channel = create(:channel, key: "youtube", provider: :youtube)
    sign_in(membership.user)
    store = ProviderConnections::OauthFlowStore.new
    state = store.issue_authorization(
      user_id: membership.user_id,
      organization_id: membership.organization_id,
      channel_id: channel.id
    )
    client = double(
      "provider client",
      exchange_code: token_set,
      discover_accounts: [candidate]
    )
    allow(Providers::Registry).to receive(:for).with("youtube").and_return(client)

    get provider_connection_oauth_callback_path(provider: "youtube"), params: {state:, code: "code"}

    expect(response).to redirect_to(
      settings_organization_channels_path(channel: channel.key, anchor: "channel-#{channel.key}")
    )
    expect(ProviderConnection.last).to have_attributes(
      organization: membership.organization,
      channel:,
      provider_account_id: "youtube-1"
    )
  end

  it "does not preserve an OAuth callback as a post-login return path" do
    get provider_connection_oauth_callback_path(provider: "youtube"), params: {state: "opaque", code: "short-lived"}

    expect(response).to redirect_to(login_path)

    user = create(:user)
    sign_in(user)
    expect(response).to redirect_to(root_path)
  end

  it "renders only the account candidates held by the server-side selection flow" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel, provider: :meta)
    sign_in(membership.user)
    token = ProviderConnections::OauthFlowStore.new.issue_selection(
      "user_id" => membership.user_id,
      "organization_id" => membership.organization_id,
      "channel_id" => channel.id,
      "candidates" => [candidate.to_h.transform_keys(&:to_s)]
    )

    get settings_organization_channel_oauth_selection_path(channel.key), params: {token:}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Creator channel", "Connect selected")
    expect(response.body).not_to include("access", "refresh")
  end

  it "disconnects an organization account without deleting it" do
    connection = create(:provider_connection)
    create(:organization_membership, organization: connection.organization, user: connection.connected_by, role: :admin)
    sign_in(connection.connected_by)

    delete settings_organization_provider_connection_path(connection)

    expect(response).to redirect_to(
      settings_organization_channels_path(
        channel: connection.channel.key,
        anchor: "channel-#{connection.channel.key}"
      )
    )
    expect(connection.reload).to be_disconnected
    expect(connection.access_token).to be_nil
  end

  it "renders account management for organization members" do
    connection = create(:provider_connection)
    member = create(:organization_membership, organization: connection.organization, role: :member).user
    sign_in(member)

    get settings_organization_channels_path(channel: connection.channel.key)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(connection.name)
    expect(response.body).not_to include("Disconnect")
  end

  it "shows reauthentication instead of disconnect for expired authorization" do
    connection = create(:provider_connection, status: :needs_reauthorization)
    create(
      :organization_membership,
      organization: connection.organization,
      user: connection.connected_by,
      role: :admin
    )
    sign_in(connection.connected_by)

    get settings_organization_channels_path(channel: connection.channel.key)

    expect(response.body).to include("Reauthenticate")
    expect(response.body).not_to include("Disconnect")
  end

  def with_provider_environment
    keys = %w[APP_HOST INSTAGRAM_CLIENT_ID INSTAGRAM_CLIENT_SECRET META_CLIENT_ID META_CLIENT_SECRET META_CONFIG_ID]
    original = ENV.to_h.slice(*keys)
    ENV["APP_HOST"] = "http://localhost:3000"
    ENV["INSTAGRAM_CLIENT_ID"] = "instagram-client"
    ENV["INSTAGRAM_CLIENT_SECRET"] = "instagram-secret"
    ENV["META_CLIENT_ID"] = "meta-client"
    ENV["META_CLIENT_SECRET"] = "meta-secret"
    ENV["META_CONFIG_ID"] = "meta-config"
    yield
  ensure
    keys.each do |key|
      original.key?(key) ? ENV[key] = original.fetch(key) : ENV.delete(key)
    end
  end

  def token_set
    Providers::TokenSet.new(
      access_token: "access",
      refresh_token: "refresh",
      expires_at: 1.hour.from_now,
      scopes: [Providers::Youtube::Client::SCOPE],
      provider_identity_id: nil,
      metadata: {}
    )
  end

  def candidate
    Providers::AccountCandidate.new(
      provider_account_id: "youtube-1",
      provider_identity_id: nil,
      name: "Creator channel",
      handle: "@creator",
      avatar_url: nil,
      access_token: "access",
      refresh_token: "refresh",
      expires_at: 1.hour.from_now,
      scopes: [Providers::Youtube::Client::SCOPE],
      metadata: {}
    )
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {
        email_address: user.email_address,
        code: "123456"
      }
    }
  end
end

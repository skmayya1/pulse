require "rails_helper"

RSpec.describe ProviderConnections::RefreshService do
  it "atomically stores rotated credentials" do
    connection = create(:provider_connection, token_expires_at: 5.minutes.from_now)
    client = double("provider client", refresh: token_set(access_token: "new-access", refresh_token: "new-refresh"))
    registry = class_double(Providers::Registry, for: client)

    result = described_class.call(connection:, registry:)

    expect(result).to be_success
    expect(connection.reload).to have_attributes(access_token: "new-access", refresh_token: "new-refresh", status: "connected")
  end

  it "marks permanent authorization failures for reauthorization" do
    connection = create(:provider_connection)
    client = double("provider client")
    allow(client).to receive(:refresh).and_raise(Providers::AuthorizationError)
    registry = class_double(Providers::Registry, for: client)

    result = described_class.call(connection:, registry:)

    expect(result.error).to eq(:needs_reauthorization)
    expect(connection.reload).to be_needs_reauthorization
  end

  it "lets transient provider failures reach Sidekiq retry handling" do
    connection = create(:provider_connection)
    client = double("provider client")
    allow(client).to receive(:refresh).and_raise(Providers::TransientError)
    registry = class_double(Providers::Registry, for: client)

    expect { described_class.call(connection:, registry:) }.to raise_error(Providers::TransientError)
  end

  def token_set(access_token:, refresh_token:)
    Providers::TokenSet.new(
      access_token:,
      refresh_token:,
      expires_at: 1.hour.from_now,
      scopes: ["basic"],
      provider_identity_id: "identity",
      metadata: {}
    )
  end
end

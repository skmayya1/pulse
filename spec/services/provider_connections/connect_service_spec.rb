require "rails_helper"

RSpec.describe ProviderConnections::ConnectService do
  it "connects and later reconnects the same external account" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel, provider: :youtube)
    first = candidate(provider_account_id: "youtube-1", access_token: "first", refresh_token: "refresh")

    initial = described_class.call(user: membership.user, organization: membership.organization, channel:, candidates: first)
    updated = described_class.call(
      user: membership.user,
      organization: membership.organization,
      channel:,
      candidates: candidate(provider_account_id: "youtube-1", access_token: "second", refresh_token: nil)
    )

    expect(initial).to be_success
    expect(updated).to be_success
    expect(ProviderConnection.count).to eq(1)
    expect(updated.connections.first).to have_attributes(access_token: "second", refresh_token: "refresh", status: "connected")
  end

  it "rejects an external account connected to another organization" do
    channel = create(:channel)
    existing = create(:provider_connection, channel:, provider_account_id: "shared")
    membership = create(:organization_membership, role: :admin)

    result = described_class.call(
      user: membership.user,
      organization: membership.organization,
      channel:,
      candidates: candidate(provider_account_id: existing.provider_account_id)
    )

    expect(result.error).to eq(:already_connected)
    expect(existing.reload.organization).not_to eq(membership.organization)
  end

  def candidate(provider_account_id:, access_token: "access", refresh_token: "refresh")
    Providers::AccountCandidate.new(
      provider_account_id:,
      provider_identity_id: "identity",
      name: "Creator account",
      handle: "@creator",
      avatar_url: nil,
      access_token:,
      refresh_token:,
      expires_at: 1.hour.from_now,
      scopes: ["basic"],
      metadata: {}
    )
  end
end

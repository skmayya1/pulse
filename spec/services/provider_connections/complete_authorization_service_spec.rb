require "rails_helper"
require_relative "../../support/flow_store_backend"

RSpec.describe ProviderConnections::CompleteAuthorizationService do
  it "connects a single discovered account" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel, provider: :tiktok)
    store = ProviderConnections::OauthFlowStore.new(backend: FlowStoreBackend.new)
    state = store.issue_authorization(user_id: membership.user_id, organization_id: membership.organization_id, channel_id: channel.id)

    result = described_class.call(
      user: membership.user,
      provider: "tiktok",
      state:,
      code: "code",
      flow_store: store,
      registry: registry_for([candidate("tiktok-1")])
    )

    expect(result).to be_success
    expect(result.connections.first).to have_attributes(organization: membership.organization, channel:)
    expect(store.consume_authorization(state)).to be_nil
  end

  it "requires selection for multiple discovered accounts" do
    membership = create(:organization_membership, role: :owner)
    channel = create(:channel, provider: :meta)
    store = ProviderConnections::OauthFlowStore.new(backend: FlowStoreBackend.new)
    state = store.issue_authorization(user_id: membership.user_id, organization_id: membership.organization_id, channel_id: channel.id)

    result = described_class.call(
      user: membership.user,
      provider: "meta",
      state:,
      code: "code",
      flow_store: store,
      registry: registry_for([candidate("one"), candidate("two")])
    )

    expect(result).to be_success
    expect(result).to be_selection_required
    expect(ProviderConnection.count).to eq(0)
  end

  it "rejects state belonging to another user and consumes it" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel)
    store = ProviderConnections::OauthFlowStore.new(backend: FlowStoreBackend.new)
    state = store.issue_authorization(user_id: create(:user).id, organization_id: membership.organization_id, channel_id: channel.id)

    result = described_class.call(
      user: membership.user,
      provider: channel.provider,
      state:,
      code: "code",
      flow_store: store,
      registry: registry_for([candidate("account")])
    )

    expect(result.error).to eq(:invalid)
    expect(store.consume_authorization(state)).to be_nil
  end

  def registry_for(candidates)
    client = double(
      "provider client",
      exchange_code: Providers::TokenSet.new(
        access_token: "token",
        refresh_token: "refresh",
        expires_at: 1.hour.from_now,
        scopes: ["basic"],
        provider_identity_id: "identity",
        metadata: {}
      ),
      discover_accounts: candidates
    )
    class_double(Providers::Registry, for: client)
  end

  def candidate(id)
    Providers::AccountCandidate.new(
      provider_account_id: id,
      provider_identity_id: "identity",
      name: "Creator",
      handle: nil,
      avatar_url: nil,
      access_token: "token",
      refresh_token: "refresh",
      expires_at: 1.hour.from_now,
      scopes: ["basic"],
      metadata: {}
    )
  end
end

require "rails_helper"
require_relative "../../support/flow_store_backend"

RSpec.describe ProviderConnections::SelectionService do
  it "connects only account IDs contained in the encrypted selection" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel)
    store = ProviderConnections::OauthFlowStore.new(backend: FlowStoreBackend.new)
    token = store.issue_selection(selection_payload(membership, channel))

    result = described_class.call(
      user: membership.user,
      channel:,
      token:,
      selected_ids: ["allowed"],
      flow_store: store
    )

    expect(result).to be_success
    expect(result.connections.map(&:provider_account_id)).to eq(["allowed"])
  end

  it "rejects an account ID supplied only by the browser" do
    membership = create(:organization_membership, role: :admin)
    channel = create(:channel)
    store = ProviderConnections::OauthFlowStore.new(backend: FlowStoreBackend.new)
    token = store.issue_selection(selection_payload(membership, channel))

    result = described_class.call(user: membership.user, channel:, token:, selected_ids: ["injected"], flow_store: store)

    expect(result.error).to eq(:invalid)
    expect(ProviderConnection.count).to eq(0)
  end

  def selection_payload(membership, channel)
    {
      "user_id" => membership.user_id,
      "organization_id" => membership.organization_id,
      "channel_id" => channel.id,
      "candidates" => [{
        "provider_account_id" => "allowed",
        "provider_identity_id" => "identity",
        "name" => "Allowed account",
        "handle" => nil,
        "avatar_url" => nil,
        "access_token" => "token",
        "refresh_token" => "refresh",
        "expires_at" => 1.hour.from_now.iso8601(6),
        "scopes" => ["basic"],
        "metadata" => {}
      }]
    }
  end
end

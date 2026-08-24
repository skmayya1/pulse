require "rails_helper"
require_relative "../../support/flow_store_backend"

RSpec.describe ProviderConnections::OauthFlowStore do
  it "stores encrypted flow data and consumes authorization state once" do
    backend = FlowStoreBackend.new
    store = described_class.new(backend:)

    token = store.issue_authorization(user_id: 1, organization_id: 2, channel_id: 3)

    expect(token).to match(/\A[A-Za-z0-9_-]{40,}\z/)
    expect(backend.values.values.first).not_to include("user_id", "organization_id")
    expect(store.consume_authorization(token)).to eq(
      "user_id" => 1,
      "organization_id" => 2,
      "channel_id" => 3
    )
    expect(store.consume_authorization(token)).to be_nil
  end

  it "allows a selection to be read before it is consumed" do
    store = described_class.new(backend: FlowStoreBackend.new)
    payload = {"user_id" => 1, "candidates" => []}
    token = store.issue_selection(payload)

    expect(store.read_selection(token)).to eq(payload)
    expect(store.consume_selection(token)).to eq(payload)
    expect(store.read_selection(token)).to be_nil
  end
end

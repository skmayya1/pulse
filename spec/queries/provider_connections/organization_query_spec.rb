require "rails_helper"

RSpec.describe ProviderConnections::OrganizationQuery do
  it "reuses an organization-scoped connection relation for lists and summaries" do
    organization = create(:organization)
    channel = create(:channel)
    active = create(:provider_connection, organization:, channel:)
    needs_authorization = create(:provider_connection, organization:, status: :needs_reauthorization)
    disconnected = create(:provider_connection, organization:, status: :disconnected, access_token: nil)
    create(:provider_connection)
    query = described_class.new(scope: ProviderConnection.all, organization:)

    expect(query.ordered(channel:)).to eq([active])
    expect(query.visible).to contain_exactly(active, needs_authorization)
    expect(query.visible).not_to include(disconnected)
    expect(query.active_counts).to eq(channel.id => 1)
    expect(query.reauthorization_channel_ids).to contain_exactly(needs_authorization.channel_id)
  end
end

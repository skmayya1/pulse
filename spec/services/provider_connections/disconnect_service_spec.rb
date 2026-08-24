require "rails_helper"

RSpec.describe ProviderConnections::DisconnectService do
  it "disconnects locally and destroys stored credentials" do
    connection = create(:provider_connection)
    membership = create(:organization_membership, organization: connection.organization, role: :admin)

    result = described_class.call(connection:, user: membership.user)

    expect(result).to be_success
    expect(connection.reload).to have_attributes(
      status: "disconnected",
      access_token: nil,
      refresh_token: nil,
      token_expires_at: nil
    )
    expect(connection.disconnected_at).to be_present
  end

  it "does not disconnect an account for an ordinary member" do
    connection = create(:provider_connection)
    membership = create(:organization_membership, organization: connection.organization, role: :member)

    result = described_class.call(connection:, user: membership.user)

    expect(result.error).to eq(:invalid)
    expect(connection.reload).to be_connected
  end
end

require "rails_helper"

RSpec.describe ProviderConnections::RefreshJob do
  it "clears request context before and after provider work" do
    connection = create(:provider_connection, status: :disconnected, disconnected_at: Time.current, access_token: nil)
    Current.user = create(:user)

    described_class.perform_now(connection.id)

    expect(Current.user).to be_nil
  end

  it "discards a missing connection" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end

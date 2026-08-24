require "rails_helper"

RSpec.describe ProviderConnections::EnqueueRefreshesJob do
  it "enqueues primitive IDs only for active connections nearing expiry" do
    expiring = create(:provider_connection, token_expires_at: 10.minutes.from_now)
    create(:provider_connection, token_expires_at: 2.hours.from_now)
    create(:provider_connection, status: :disconnected, disconnected_at: Time.current, access_token: nil, token_expires_at: 5.minutes.from_now)

    expect { described_class.perform_now }
      .to enqueue_job(ProviderConnections::RefreshJob).with(expiring.id).exactly(:once)
  end
end

require "rails_helper"

RSpec.describe Sessions::PruneExpiredJob do
  after { Current.clear }

  it "prunes expired sessions on the low queue without inheriting request context" do
    active_session = create(:session)
    create(:session, expires_at: 1.minute.ago)
    Current.establish!(active_session)

    expect { described_class.perform_now }.to change(Session, :count).by(-1)
    expect(Current.user).to be_nil
    expect(described_class.new.queue_name).to eq("low")
  end
end

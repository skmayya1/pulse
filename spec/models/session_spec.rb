require "rails_helper"

RSpec.describe Session do
  describe ".issue_for" do
    it "persists only a digest of a random token" do
      user = create(:user)

      issued = described_class.issue_for(user:, user_agent: "Browser", ip_address: "127.0.0.1")

      expect(issued.token).to be_present
      expect(issued.session.token_digest).to eq(Digest::SHA256.hexdigest(issued.token))
      expect(issued.session.token_digest).not_to eq(issued.token)
      expect(issued.session.expires_at).to be_within(2.seconds).of(30.days.from_now)
    end
  end

  describe ".find_by_token" do
    it "finds a session by hashing the raw token" do
      user = create(:user)
      issued = described_class.issue_for(user:, user_agent: nil, ip_address: nil)

      expect(described_class.find_by_token(issued.token)).to eq(issued.session)
    end
  end

  it "can be revoked and recognizes expiry" do
    session = create(:session, expires_at: 1.minute.ago)

    expect(session).not_to be_active
    session.revoke!
    expect(session).to be_destroyed
  end

  it "records activity at most once per hour" do
    session = create(:session, last_active_at: 2.hours.ago)

    expect { session.record_activity! }.to change { session.reload.last_active_at }
    expect { session.record_activity! }.not_to change { session.reload.last_active_at }
  end

  it "prunes expired sessions" do
    expired = create(:session, expires_at: 1.minute.ago)
    active = create(:session)

    expect { described_class.prune_expired! }.to change(described_class, :count).by(-1)
    expect(described_class.exists?(expired.id)).to be(false)
    expect(described_class.exists?(active.id)).to be(true)
  end
end

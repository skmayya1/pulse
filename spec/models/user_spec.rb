require "rails_helper"

RSpec.describe User do
  it "normalizes email addresses before validation" do
    user = described_class.create!(email_address: "  Creator@Example.COM ", verified_at: Time.current)

    expect(user.email_address).to eq("creator@example.com")
  end

  it "enforces case-insensitive email uniqueness" do
    create(:user, email_address: "creator@example.com")

    duplicate = build(:user, email_address: "CREATOR@example.com")
    expect(duplicate).not_to be_valid
  end

  it "enforces unique Google account ownership" do
    create(:user, google_uid: "google-123")

    duplicate = build(:user, google_uid: "google-123")
    expect(duplicate).not_to be_valid
  end
end

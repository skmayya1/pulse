require "rails_helper"

RSpec.describe Authentication::ResolveUserService do
  it "creates a user for the first verified email login" do
    expect {
      @result = described_class.call(
        provider: "email",
        uid: "creator@example.com",
        email_address: "Creator@Example.com",
        name: nil
      )
    }.to change(User, :count).by(1)

    expect(@result).to be_success
    expect(@result).to be_created
    expect(@result.user.email_address).to eq("creator@example.com")
    expect(@result.user.google_uid).to be_nil
  end

  it "resolves Google by its stable UID before email" do
    user = create(:user, email_address: "creator@example.com", google_uid: "google-123")

    result = described_class.call(
      provider: "google_oauth2",
      uid: "google-123",
      email_address: user.email_address,
      name: "Creator"
    )

    expect(result.user).to eq(user)
  end

  it "links Google to an existing verified email" do
    user = create(:user, email_address: "creator@example.com")

    result = described_class.call(
      provider: "google_oauth2",
      uid: "google-123",
      email_address: "CREATOR@example.com",
      name: "Creator"
    )

    expect(result).to be_success
    expect(result.user).to eq(user)
    expect(result).not_to be_created
    expect(user.reload.google_uid).to eq("google-123")
  end

  it "rejects Google UID and email ownership conflicts" do
    create(:user, email_address: "first@example.com", google_uid: "google-123")
    create(:user, email_address: "creator@example.com")

    result = described_class.call(
      provider: "google_oauth2",
      uid: "google-123",
      email_address: "creator@example.com",
      name: "Creator"
    )

    expect(result).not_to be_success
    expect(result.error).to eq(:google_conflict)
  end

  it "does not create duplicate users when called again" do
    attributes = {
      provider: "email",
      uid: "creator@example.com",
      email_address: "creator@example.com",
      name: nil
    }
    described_class.call(**attributes)

    expect { described_class.call(**attributes) }.not_to change(User, :count)
  end
end

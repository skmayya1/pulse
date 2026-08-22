require "rails_helper"

RSpec.describe OrganizationInvitation do
  it "normalizes its email and permits only admin and member roles" do
    invitation = build(:organization_invitation, email_address: " Creator@Example.COM ", role: :admin)

    expect(invitation).to be_valid
    invitation.validate
    expect(invitation.email_address).to eq("creator@example.com")
    expect(build(:organization_invitation, role: :owner)).not_to be_valid
  end

  it "allows only one pending invitation per organization and email" do
    invitation = create(:organization_invitation, email_address: "creator@example.com")

    duplicate = build(
      :organization_invitation,
      organization: invitation.organization,
      email_address: "CREATOR@example.com"
    )

    expect(duplicate).not_to be_valid
  end

  it "finds invitations from a raw token" do
    raw_token = SecureRandom.urlsafe_base64(32)
    invitation = create(
      :organization_invitation,
      token_digest: Digest::SHA256.hexdigest(raw_token)
    )

    expect(described_class.find_by_token(raw_token)).to eq(invitation)
    expect(described_class.find_by_token("wrong-token")).to be_nil
  end

  it "scopes invitation lifecycle states" do
    pending = create(:organization_invitation)
    expired = create(:organization_invitation, expires_at: 1.minute.ago)
    accepted = create(:organization_invitation, accepted_at: Time.current)
    revoked = create(:organization_invitation, revoked_at: Time.current)

    expect(described_class.pending).to contain_exactly(pending)
    expect(described_class.expired).to contain_exactly(expired)
    expect(described_class.accepted).to contain_exactly(accepted)
    expect(described_class.revoked).to contain_exactly(revoked)
  end
end

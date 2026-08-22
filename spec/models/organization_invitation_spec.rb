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
end

require "rails_helper"

RSpec.describe OrganizationInvitations::EnsureAcceptanceJob do
  after { Current.clear }

  it "retries acceptance for the invitation's specific organization" do
    invitation = create(:organization_invitation)
    user = create(:user, email_address: invitation.email_address)
    create(:organization_membership, user:)
    Current.establish!(create(:session, user:))

    expect {
      described_class.perform_now(user.id, invitation.id)
    }.to change(OrganizationMembership, :count).by(1)

    expect(user.organization_memberships.exists?(organization: invitation.organization)).to be(true)
    expect(Current.user).to be_nil
  end

  it "is a no-op after acceptance is complete" do
    invitation = create(:organization_invitation, accepted_at: Time.current)
    user = create(:user, email_address: invitation.email_address)
    create(:organization_membership, organization: invitation.organization, user:)

    expect {
      described_class.perform_now(user.id, invitation.id)
    }.not_to change(OrganizationMembership, :count)
  end

  it "does not accept an invalid invitation" do
    invitation = create(:organization_invitation, expires_at: 1.minute.ago)
    user = create(:user, email_address: invitation.email_address)

    expect {
      described_class.perform_now(user.id, invitation.id)
    }.not_to change(OrganizationMembership, :count)
  end

  it "does not accept a superseded invitation" do
    organization = create(:organization)
    owner = create(:organization_membership, organization:, role: :owner).user
    first = OrganizationInvitations::IssueService.call(
      organization:,
      invited_by: owner,
      email_address: "invited@example.com",
      role: :member
    )
    OrganizationInvitations::IssueService.call(
      organization:,
      invited_by: owner,
      email_address: "invited@example.com",
      role: :member
    )
    user = create(:user, email_address: "invited@example.com")

    expect {
      described_class.perform_now(user.id, first.invitation.id)
    }.not_to change(OrganizationMembership, :count)
  end

  it "discards missing records" do
    expect { described_class.perform_now(-1, -1) }.not_to raise_error
  end
end

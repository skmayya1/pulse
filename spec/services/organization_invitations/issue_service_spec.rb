require "rails_helper"

RSpec.describe OrganizationInvitations::IssueService do
  include ActiveSupport::Testing::TimeHelpers

  it "issues a seven-day invitation without persisting the plaintext token" do
    organization = create(:organization)
    owner = create_member(organization, :owner)

    result = described_class.call(
      organization:,
      invited_by: owner,
      email_address: " Invited@Example.com ",
      role: :admin
    )

    expect(result).to be_success
    expect(result.token).to be_present
    expect(result.invitation.email_address).to eq("invited@example.com")
    expect(result.invitation.expires_at).to be_within(2.seconds).of(7.days.from_now)
    expect(result.invitation.token_digest).to eq(Digest::SHA256.hexdigest(result.token))
    expect(result.invitation.attributes.values).not_to include(result.token)
  end

  it "allows admins to invite members but not admins" do
    organization = create(:organization)
    admin = create_member(organization, :admin)

    expect(issue(organization, admin, role: :member)).to be_success
    expect(issue(organization, admin, email: "admin@example.com", role: :admin).error).to eq(:unauthorized)
  end

  it "rejects outsiders and existing organization members" do
    organization = create(:organization)
    existing_member = create_member(organization, :member)

    expect(issue(organization, create(:user)).error).to eq(:unauthorized)
    expect(issue(organization, create_member(organization, :owner), email: existing_member.email_address).error)
      .to eq(:already_member)
  end

  it "rotates a pending invitation token" do
    organization = create(:organization)
    owner = create_member(organization, :owner)
    first = issue(organization, owner)
    second = issue(organization, owner)

    expect(second).to be_success
    expect(second.invitation).not_to eq(first.invitation)
    expect(first.invitation.reload.revoked_at).to be_present
    expect(second.token).not_to eq(first.token)
    expect(OrganizationInvitation.find_by_token(first.token).revoked_at).to be_present
    expect(OrganizationInvitation.find_by_token(second.token)).to eq(second.invitation)
  end

  def create_member(organization, role)
    create(:organization_membership, organization:, role:).user
  end

  def issue(organization, invited_by, email: "invited@example.com", role: :member)
    described_class.call(organization:, invited_by:, email_address: email, role:)
  end
end

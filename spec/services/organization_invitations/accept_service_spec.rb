require "rails_helper"

RSpec.describe OrganizationInvitations::AcceptService do
  include ActiveSupport::Testing::TimeHelpers

  it "creates the invited membership and consumes the invitation atomically" do
    invitation, user = invitation_for(role: :admin)

    expect {
      @result = described_class.call(invitation:, user:)
    }.to change(OrganizationMembership, :count).by(1)

    expect(@result).to be_success
    expect(@result.membership).to be_admin
    expect(@result.membership.user).to eq(user)
    expect(invitation.reload.accepted_at).to be_present
  end

  it "never downgrades an existing membership" do
    invitation, user = invitation_for(role: :member)
    existing = create(:organization_membership, organization: invitation.organization, user:, role: :admin)

    result = described_class.call(invitation:, user:)

    expect(result).to be_success
    expect(existing.reload).to be_admin
    expect(OrganizationMembership.where(organization: invitation.organization, user:).count).to eq(1)
  end

  it "rejects mismatched, expired, revoked, and used invitations" do
    invitation, = invitation_for
    expect(described_class.call(invitation:, user: create(:user)).error).to eq(:invalid)

    invitation.update!(expires_at: 1.minute.ago)
    expect(described_class.call(invitation:, user: user_for(invitation)).error).to eq(:invalid)

    invitation.update!(expires_at: 1.day.from_now, revoked_at: Time.current)
    expect(described_class.call(invitation:, user: user_for(invitation)).error).to eq(:invalid)

    invitation.update!(revoked_at: nil)
    user = user_for(invitation)
    expect(described_class.call(invitation:, user:)).to be_success
    expect(described_class.call(invitation:, user:).error).to eq(:invalid)
  end

  def invitation_for(role: :member)
    invitation = create(:organization_invitation, role:)
    [invitation, user_for(invitation)]
  end

  def user_for(invitation)
    User.find_or_create_by!(email_address: invitation.email_address) do |user|
      user.verified_at = Time.current
    end
  end
end

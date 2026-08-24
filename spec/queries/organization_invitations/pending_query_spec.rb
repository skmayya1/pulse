require "rails_helper"

RSpec.describe OrganizationInvitations::PendingQuery do
  it "returns pending invitations for the organization newest first" do
    organization = create(:organization)
    older = create(:organization_invitation, organization:, created_at: 1.day.ago)
    newer = create(:organization_invitation, organization:, created_at: Time.current)
    create(:organization_invitation, organization:, accepted_at: Time.current)
    create(:organization_invitation)

    result = described_class.call(scope: OrganizationInvitation.all, organization:)

    expect(result).to eq([newer, older])
    expect(result.first.association(:invited_by)).to be_loaded
  end
end

require "rails_helper"

RSpec.describe OrganizationMemberships::ListQuery do
  it "returns only the organization's memberships in creation order" do
    organization = create(:organization)
    later = create(:organization_membership, organization:, created_at: 1.day.from_now)
    earlier = create(:organization_membership, organization:, created_at: Time.current)
    create(:organization_membership)

    result = described_class.call(scope: OrganizationMembership.all, organization:)

    expect(result).to eq([earlier, later])
    expect(result.first.association(:user)).to be_loaded
  end
end

require "rails_helper"

RSpec.describe OrganizationMembership do
  it "supports owner, admin, and member roles" do
    expect(build(:organization_membership, role: :owner)).to be_valid
    expect(build(:organization_membership, role: :admin)).to be_valid
    expect(build(:organization_membership, role: :member)).to be_valid
    expect(build(:organization_membership, role: :unknown)).not_to be_valid
  end

  it "compares roles using the organization hierarchy" do
    expect(build(:organization_membership, role: :owner)).to be_role_at_least(:admin)
    expect(build(:organization_membership, role: :admin)).to be_role_at_least(:member)
    expect(build(:organization_membership, role: :member)).not_to be_role_at_least(:admin)
  end

  it "allows a user to belong to multiple organizations only once each" do
    user = create(:user)
    first_organization = create(:organization)
    second_organization = create(:organization)
    create(:organization_membership, organization: first_organization, user:)

    expect(build(:organization_membership, organization: first_organization, user:)).not_to be_valid
    expect(build(:organization_membership, organization: second_organization, user:)).to be_valid
  end
end

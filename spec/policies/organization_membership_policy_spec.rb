require "rails_helper"

RSpec.describe OrganizationMembershipPolicy do
  after { Current.clear }

  it "allows every organization member to view memberships" do
    organization = create(:organization)
    target = create(:organization_membership, organization:)

    expect(policy_for(create_member(organization, :member), target)).to be_show
    expect(policy_for(create(:user), target)).not_to be_show
  end

  it "allows admins to add and remove ordinary members only" do
    organization = create(:organization)
    admin = create_member(organization, :admin)

    expect(policy_for(admin, build(:organization_membership, organization:, role: :member))).to be_create
    expect(policy_for(admin, build(:organization_membership, organization:, role: :admin))).not_to be_create
    expect(policy_for(admin, create(:organization_membership, organization:, role: :member))).to be_destroy
    expect(policy_for(admin, create(:organization_membership, organization:, role: :admin))).not_to be_destroy
  end

  it "allows owners to manage admins and members but not owners" do
    organization = create(:organization)
    owner = create_member(organization, :owner)
    admin = create(:organization_membership, organization:, role: :admin)
    other_owner = create(:organization_membership, organization:, role: :owner)

    expect(policy_for(owner, admin)).to be_update
    expect(policy_for(owner, admin)).to be_destroy
    expect(policy_for(owner, other_owner)).not_to be_update
    expect(policy_for(owner, other_owner)).not_to be_destroy
  end

  it "scopes memberships to organizations the user belongs to" do
    user = create(:user)
    included = create(:organization_membership)
    excluded = create(:organization_membership)
    create(:organization_membership, organization: included.organization, user:)
    Current.user = user

    result = described_class::Scope.new(Current, OrganizationMembership).resolve

    expect(result).to include(included)
    expect(result).not_to include(excluded)
  end

  def create_member(organization, role)
    create(:organization_membership, organization:, role:).user
  end

  def policy_for(user, membership)
    Current.user = user
    described_class.new(Current, membership)
  end
end

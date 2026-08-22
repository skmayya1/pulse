require "rails_helper"

RSpec.describe OrganizationPolicy do
  after { Current.clear }

  it "allows authenticated users to list and create organizations" do
    policy = policy_for(create(:user), Organization.new)

    expect(policy).to be_index
    expect(policy).to be_create
  end

  it "allows members to view, admins to update, and only owners to destroy" do
    organization = create(:organization)

    expect(policy_for(create_member(organization, :member), organization)).to be_show
    expect(policy_for(create_member(organization, :member), organization)).not_to be_update
    expect(policy_for(create_member(organization, :admin), organization)).to be_update
    expect(policy_for(create_member(organization, :admin), organization)).not_to be_destroy
    expect(policy_for(create_member(organization, :owner), organization)).to be_destroy
  end

  it "denies users outside the organization" do
    organization = create(:organization)

    expect(policy_for(create(:user), organization)).not_to be_show
  end

  it "scopes organizations to the current user's memberships" do
    user = create(:user)
    included = create(:organization)
    excluded = create(:organization)
    create(:organization_membership, organization: included, user:)
    Current.user = user

    expect(described_class::Scope.new(Current, Organization).resolve).to contain_exactly(included)
    expect(described_class::Scope.new(Current, Organization).resolve).not_to include(excluded)
  end

  def create_member(organization, role)
    create(:organization_membership, organization:, role:).user
  end

  def policy_for(user, organization)
    Current.user = user
    described_class.new(Current, organization)
  end
end

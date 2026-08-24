require "rails_helper"

RSpec.describe ProviderConnectionPolicy do
  after { Current.clear }

  it "allows members to view and admins to manage provider connections" do
    connection = create(:provider_connection)
    member = create_member(connection.organization, :member)
    admin = create_member(connection.organization, :admin)

    expect(policy_for(member, connection)).to be_show
    expect(policy_for(member, connection)).not_to be_create
    expect(policy_for(member, connection)).not_to be_update
    expect(policy_for(member, connection)).not_to be_destroy
    expect(policy_for(admin, connection)).to be_create
    expect(policy_for(admin, connection)).to be_update
    expect(policy_for(admin, connection)).to be_destroy
  end

  it "scopes provider connections to the user's organizations" do
    included = create(:provider_connection)
    excluded = create(:provider_connection)
    user = create_member(included.organization, :member)
    Current.user = user

    result = described_class::Scope.new(Current, ProviderConnection).resolve

    expect(result).to include(included)
    expect(result).not_to include(excluded)
  end

  def create_member(organization, role)
    create(:organization_membership, organization:, role:).user
  end

  def policy_for(user, record)
    Current.user = user
    described_class.new(Current, record)
  end
end

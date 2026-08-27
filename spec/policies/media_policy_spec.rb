require "rails_helper"

RSpec.describe MediaPolicy do
  after { Current.clear }

  it "allows organization members to list and upload library media" do
    organization = create(:organization)
    member = create_member(organization, :member)
    media = build(:media, uploadable: organization)

    expect(policy_for(member, media)).to be_index
    expect(policy_for(member, media)).to be_create
  end

  it "scopes library media to the member's organizations" do
    included = create(:media)
    excluded = create(:media)
    user = create_member(included.uploadable, :member)
    Current.user = user

    result = described_class::Scope.new(Current, Media).resolve

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

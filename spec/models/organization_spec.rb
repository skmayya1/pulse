require "rails_helper"

RSpec.describe Organization do
  it "requires a name and defaults to UTC" do
    organization = described_class.create!(name: "Pulse Studio")

    expect(organization.time_zone).to eq("UTC")
    expect(described_class.new).not_to be_valid
  end

  it "exposes members through organization memberships" do
    organization = create(:organization)
    user = create(:user)
    create(:organization_membership, organization:, user:)

    expect(organization.members).to contain_exactly(user)
    expect(user.organizations).to contain_exactly(organization)
  end
end

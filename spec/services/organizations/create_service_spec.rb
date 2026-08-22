require "rails_helper"

RSpec.describe Organizations::CreateService do
  it "atomically creates an organization and owner membership" do
    user = create(:user)

    expect {
      @result = described_class.call(user:, name: "Pulse Studio")
    }.to change(Organization, :count).by(1)
      .and change(OrganizationMembership, :count).by(1)

    expect(@result).to be_success
    expect(@result.organization.name).to eq("Pulse Studio")
    expect(@result.organization.time_zone).to eq("UTC")
    expect(@result.membership).to be_owner
    expect(@result.membership.user).to eq(user)
  end

  it "persists nothing when the organization is invalid" do
    expect {
      @result = described_class.call(user: create(:user), name: "")
    }.not_to change(Organization, :count)

    expect(@result).not_to be_success
    expect(@result.error).to eq(:invalid)
  end
end

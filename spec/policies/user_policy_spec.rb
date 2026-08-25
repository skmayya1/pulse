require "rails_helper"

RSpec.describe UserPolicy do
  after { Current.clear }

  it "allows a user to view and update their own profile" do
    user = create(:user)
    policy = policy_for(user, user)

    expect(policy).to be_show
    expect(policy).to be_update
  end

  it "denies access to another user's profile" do
    policy = policy_for(create(:user), create(:user))

    expect(policy).not_to be_show
    expect(policy).not_to be_update
  end

  def policy_for(user, record)
    Current.user = user
    described_class.new(Current, record)
  end
end

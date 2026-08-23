require "rails_helper"

RSpec.describe SettingsPolicy do
  after { Current.clear }

  it "allows authenticated users to access settings" do
    Current.user = create(:user)

    expect(described_class.new(Current, :settings)).to be_show
  end

  it "denies signed-out users" do
    expect(described_class.new(Current, :settings)).not_to be_show
  end
end

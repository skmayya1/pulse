require "rails_helper"

RSpec.describe Current do
  after { described_class.clear }

  it "establishes the complete request context" do
    user = create(:user)
    session = create(:session, user:)

    described_class.establish!(session)

    expect(described_class.session).to eq(session)
    expect(described_class.user).to eq(user)
  end

  it "clears all request attributes" do
    described_class.establish!(create(:session))

    described_class.clear

    expect(described_class.attributes.values).to all(be_nil)
  end
end

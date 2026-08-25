require "rails_helper"

RSpec.describe Channel do
  it "accepts supported providers and rejects unknown ones" do
    expect(build(:channel, provider: :instagram)).to be_valid
    expect(build(:channel, provider: :meta)).to be_valid
    expect(build(:channel, provider: :unknown)).not_to be_valid
  end

  it "identifies each catalog channel by its key" do
    channel = create(:channel, key: "instagram")

    expect(build(:channel, key: channel.key)).not_to be_valid
  end

  it "returns enabled channels in their configured order" do
    later = create(:channel, position: 2)
    earlier = create(:channel, position: 1)
    create(:channel, enabled: false, position: 0)

    expect(described_class.enabled.ordered).to eq([earlier, later])
  end

  it "defaults configuration to an empty object" do
    expect(build(:channel).configuration).to eq({})
  end

  it "upserts the catalog channels used by organization settings" do
    Channel.upsert_catalog!

    expect(Channel.ordered.map { |channel| [channel.key, channel.provider] }).to eq([
      %w[instagram instagram],
      %w[facebook meta],
      %w[tiktok tiktok],
      %w[youtube youtube]
    ])
  end

  it "restricts catalog channel deletion while connections exist" do
    channel = create(:channel)
    create(:provider_connection, channel:)

    expect(channel.destroy).to be(false)
    expect(channel.errors[:base]).to be_present
  end
end

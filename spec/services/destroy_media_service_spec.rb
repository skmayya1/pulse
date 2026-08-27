require "rails_helper"

RSpec.describe DestroyMediaService do
  it "deletes media that is not attached to a post" do
    media = create(:media)

    result = described_class.call(media:)

    expect(result).to be_success
    expect(Media.exists?(media.id)).to be(false)
  end

  it "does not delete media attached to a post" do
    media = create(:media)
    create(:media_attachment, media:, post: create(:post, organization: media.uploadable))

    result = described_class.call(media:)

    expect(result.error).to eq(:in_use)
    expect(media.reload).to be_persisted
  end
end

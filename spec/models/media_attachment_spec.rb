require "rails_helper"

RSpec.describe MediaAttachment do
  it "joins a post to library media in position order" do
    post = create(:post)
    first = create(:media, uploadable: post.organization)
    second = create(:media, uploadable: post.organization)
    create(:media_attachment, post:, media: second, position: 1)
    create(:media_attachment, post:, media: first, position: 0)

    expect(post.media).to eq([first, second])
    expect(first.posts).to contain_exactly(post)
  end

  it "does not attach the same media to the same post twice" do
    post = create(:post)
    media = create(:media, uploadable: post.organization)
    create(:media_attachment, post:, media:)

    expect(build(:media_attachment, post:, media:)).not_to be_valid
  end

  it "allows the same media on different posts" do
    organization = create(:organization)
    media = create(:media, uploadable: organization)
    first_post = create(:post, organization:)
    second_post = create(:post, organization:)
    create(:media_attachment, post: first_post, media:)

    expect(build(:media_attachment, post: second_post, media:)).to be_valid
  end
end

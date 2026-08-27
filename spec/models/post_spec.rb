require "rails_helper"

RSpec.describe Post do
  it "belongs to an organization and creator" do
    user = create(:user)
    organization = create(:organization)
    post = create(:post, organization:, created_by: user)

    expect(post.organization).to eq(organization)
    expect(post.created_by).to eq(user)
    expect(organization.posts).to contain_exactly(post)
    expect(user.created_posts).to contain_exactly(post)
  end

  it "defaults status to draft" do
    expect(create(:post).status).to eq("draft")
  end

  it "rejects unknown statuses" do
    post = build(:post, status: "archived")

    expect(post).not_to be_valid
  end

  it "normalizes a blank caption to nil" do
    post = build(:post, caption: "  ")
    post.valid?

    expect(post.caption).to be_nil
  end

  it "is valid with a caption and no media" do
    expect(build(:post, caption: "Hello")).to be_valid
  end

  it "is valid with media and no caption" do
    organization = create(:organization)
    post = build(:post, organization:, caption: nil)
    post.media_attachments.build(
      media: create(:media, uploadable: organization),
      position: 0
    )

    expect(post).to be_valid
  end

  it "is invalid with neither caption nor media" do
    expect(build(:post, caption: nil)).not_to be_valid
  end
end

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
end

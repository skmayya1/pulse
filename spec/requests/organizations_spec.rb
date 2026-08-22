require "rails_helper"

RSpec.describe "Organizations" do
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
  end

  it "redirects an authenticated user without a membership to organization creation" do
    sign_in(create(:user))

    get root_path

    expect(response).to redirect_to(new_organization_path)
  end

  it "allows an organization member into the application" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "creates an organization and owner membership" do
    user = create(:user)
    sign_in(user)

    expect {
      post organizations_path, params: {organization: {name: "Pulse Studio"}}
    }.to change(Organization, :count).by(1)
      .and change(OrganizationMembership, :count).by(1)

    expect(response).to redirect_to(root_path)
    expect(OrganizationMembership.last).to have_attributes(user:, role: "owner")
  end

  it "renders invalid organization input without partial persistence" do
    sign_in(create(:user))

    expect {
      post organizations_path, params: {organization: {name: ""}}
    }.not_to change(Organization, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "shows only the signed-in user's organizations" do
    membership = create(:organization_membership)
    excluded_organization = create(:organization)
    sign_in(membership.user)

    get root_path

    expect(response.body).to include(membership.organization.name)
    expect(response.body).not_to include(excluded_organization.name)
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
  end
end

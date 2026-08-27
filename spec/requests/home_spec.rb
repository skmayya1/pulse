require "rails_helper"

RSpec.describe "Home" do
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

  it "renders the app for an organization member" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(membership.user.email_address, membership.organization.name)
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
  end
end

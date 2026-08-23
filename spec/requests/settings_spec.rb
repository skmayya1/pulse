require "rails_helper"

RSpec.describe "Settings" do
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

  it "requires an organization membership" do
    sign_in(create(:user))

    get settings_path

    expect(response).to redirect_to(new_organization_path)
  end

  it "renders each settings section for an organization member" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    [
      settings_path,
      settings_profile_path,
      settings_preferences_path,
      settings_notifications_path,
      settings_organization_general_path,
      settings_organization_channels_path,
      settings_organization_members_path
    ].each do |path|
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Settings")
    end
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
  end
end

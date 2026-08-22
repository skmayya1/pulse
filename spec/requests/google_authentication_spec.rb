require "rails_helper"

RSpec.describe "Google authentication" do
  around do |example|
    previous_test_mode = OmniAuth.config.test_mode
    OmniAuth.config.test_mode = true
    example.run
  ensure
    OmniAuth.config.test_mode = previous_test_mode
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    Current.clear
  end

  it "creates an account from a verified Google email without storing provider tokens" do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth(email_verified: true)

    expect { get "/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]} }
      .to change(User, :count).by(1)

    expect(response).to redirect_to(root_path)
    user = User.last
    expect(user.google_uid).to eq("google-123")
    expect(user.attributes.keys).not_to include("access_token", "refresh_token")
    expect(user.name).to eq("Pulse Creator")
  end

  it "rejects an unverified Google email" do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth(email_verified: false)

    expect {
      get "/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}
    }.not_to change(User, :count)
    expect(response).to redirect_to(login_path)
  end

  it "rejects a Google ownership conflict" do
    create(:user, email_address: "first@example.com", google_uid: "google-123")
    create(:user, email_address: "creator@example.com")
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth(email_verified: true)

    get "/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}

    expect(response).to redirect_to(login_path)
    expect(Session.count).to eq(0)
  end

  def google_auth(email_verified:)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-123",
      info: {email: "creator@example.com", name: "Pulse Creator"},
      credentials: {token: "must-not-persist", refresh_token: "must-not-persist"},
      extra: {raw_info: {email_verified:}}
    )
  end
end

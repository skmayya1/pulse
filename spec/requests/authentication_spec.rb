require "rails_helper"

RSpec.describe "Passwordless authentication" do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    travel_back
    Rails.cache = original_cache
    Current.clear
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
  end

  it "requires authentication for the application" do
    get root_path

    expect(response).to redirect_to(login_path)
  end

  it "returns to login after requesting an email code" do
    post login_path, params: {authentication: {email_address: "creator@example.com"}}

    expect(response).to redirect_to(login_path)
  end

  it "verifies an OTP, creates the account, and stores an opaque cookie" do
    Authentication::OtpService.send_code(email_address: "creator@example.com", ip_address: "127.0.0.1")

    expect {
      post login_path, params: {
        authentication: {email_address: "creator@example.com", code: "123456"}
      }
    }.to change(User, :count).by(1)
      .and change(Session, :count).by(1)

    expect(response).to redirect_to(root_path)
    cookie = response.cookies[Authentication::SESSION_COOKIE.to_s]
    expect(cookie).to be_present
    expect(Session.last.token_digest).not_to eq(cookie)
  end

  it "returns the same login error for invalid verification" do
    post login_path, params: {
      authentication: {email_address: "missing@example.com", code: "123456"}
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("The code could not be verified")
  end

  it "revokes the database session and clears the cookie on logout" do
    user = create(:user)
    sign_in_with_otp(user.email_address)

    expect { delete logout_path }.to change(Session, :count).by(-1)
    expect(response).to redirect_to(login_path)
    expect(response.cookies[Authentication::SESSION_COOKIE.to_s]).to be_nil
  end

  it "revokes an expired cookie-backed session" do
    user = create(:user)
    sign_in_with_otp(user.email_address)
    authenticated_session = Session.last
    authenticated_session.update!(expires_at: 1.minute.ago)

    get root_path

    expect(response).to redirect_to(login_path)
    expect(Session.exists?(authenticated_session.id)).to be(false)
  end

  it "resets Current after each request" do
    get login_path

    expect(Current.user).to be_nil
  end

  def sign_in_with_otp(email_address)
    Authentication::OtpService.send_code(email_address:, ip_address: "127.0.0.1")
    post login_path, params: {authentication: {email_address:, code: "123456"}}
  end
end

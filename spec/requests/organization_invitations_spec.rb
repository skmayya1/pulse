require "rails_helper"

RSpec.describe "Organization invitations" do
  include ActiveJob::TestHelper

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

  after do
    clear_enqueued_jobs
    Current.clear
  end

  it "returns a signed-out user to the invitation after authentication" do
    raw_token, invitation = invitation_for("creator@example.com")

    get organization_invitation_path(raw_token)
    expect(response).to redirect_to(login_path)

    Authentication::OtpService.send_code(email_address: invitation.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: invitation.email_address, code: development_code}
    }

    expect(response).to redirect_to(organization_invitation_path(raw_token))
    follow_redirect!
    expect(response).to redirect_to(root_path)
    expect(invitation.organization.members).to include(User.find_by!(email_address: invitation.email_address))
  end

  it "returns from Google authentication and accepts the invitation" do
    raw_token, invitation = invitation_for("creator@example.com")
    get organization_invitation_path(raw_token)

    authentication = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "invited-google-user",
      info: {email: invitation.email_address, name: "Pulse Creator"},
      extra: {raw_info: {email_verified: true}}
    )
    get "/auth/google_oauth2/callback", env: {"omniauth.auth" => authentication}

    expect(response).to redirect_to(organization_invitation_path(raw_token))
    follow_redirect!
    expect(response).to redirect_to(root_path)
    expect(invitation.organization.members.find_by(email_address: invitation.email_address)).to be_present
  end

  it "accepts a matching invitation and schedules a two-minute recovery check" do
    raw_token, invitation = invitation_for("creator@example.com")
    user = create(:user, email_address: invitation.email_address)
    sign_in(user)

    expect {
      get organization_invitation_path(raw_token)
    }.to change(OrganizationMembership, :count).by(1)
      .and have_enqueued_job(OrganizationInvitations::EnsureAcceptanceJob).with(user.id, invitation.id)

    expect(response).to redirect_to(root_path)
    expect(invitation.reload.accepted_at).to be_present
    scheduled_at = enqueued_jobs.last.fetch(:at)
    expect(Time.zone.at(scheduled_at)).to be_within(2.seconds).of(2.minutes.from_now)
  end

  it "rejects invalid and mismatched invitations generically without scheduling recovery" do
    raw_token, = invitation_for("invited@example.com")
    sign_in(create(:user, email_address: "someone-else@example.com"))

    expect {
      get organization_invitation_path(raw_token)
    }.not_to have_enqueued_job(OrganizationInvitations::EnsureAcceptanceJob)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(OrganizationInvitationsController::GENERIC_FAILURE)
  end

  it "rejects malformed tokens generically" do
    sign_in(create(:user))

    get organization_invitation_path("malformed")

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(OrganizationInvitationsController::GENERIC_FAILURE)
  end

  it "rejects expired, revoked, and used invitations with the same message" do
    %i[expired revoked used].each do |state|
      raw_token, invitation = invitation_for("#{state}@example.com")
      invitation.update!(invitation_state(state))
      sign_in(create(:user, email_address: invitation.email_address))

      get organization_invitation_path(raw_token)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(OrganizationInvitationsController::GENERIC_FAILURE)
      delete logout_path
    end
  end

  def invitation_for(email_address)
    raw_token = SecureRandom.urlsafe_base64(32)
    invitation = create(
      :organization_invitation,
      email_address:,
      token_digest: Digest::SHA256.hexdigest(raw_token)
    )
    [raw_token, invitation]
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: development_code}
    }
  end

  def development_code
    "123456"
  end

  def invitation_state(state)
    case state
    when :expired then {expires_at: 1.minute.ago}
    when :revoked then {revoked_at: Time.current}
    when :used then {accepted_at: Time.current}
    end
  end
end

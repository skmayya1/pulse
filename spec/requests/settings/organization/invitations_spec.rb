require "rails_helper"

RSpec.describe "Settings organization invitations" do
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    ActionMailer::Base.deliveries.clear
    example.run
  ensure
    Rails.cache = original_cache
    ActionMailer::Base.deliveries.clear
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
  end

  it "shows an organization's members and pending invitations to an owner" do
    organization = create(:organization)
    owner = create(:organization_membership, organization:, role: :owner).user
    member = create(:organization_membership, organization:, role: :member).user
    invitation = create(:organization_invitation, organization:, invited_by: owner, email_address: "pending@example.com")
    sign_in(owner)

    get settings_organization_members_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(owner.email_address, member.email_address, invitation.email_address, "Invite a member")
  end

  it "issues an invitation and emails its secure acceptance link" do
    organization = create(:organization, name: "Pulse Studio")
    owner = create(:organization_membership, organization:, role: :owner).user
    sign_in(owner)

    expect {
      post settings_organization_invitations_path, params: {
        organization_invitation: {email_address: "invitee@example.com", role: "admin"}
      }
    }.to change(OrganizationInvitation, :count).by(1)
      .and change { ActionMailer::Base.deliveries.count }.by(1)

    invitation = OrganizationInvitation.last

    expect(response).to redirect_to(settings_organization_members_path)
    expect(invitation).to have_attributes(email_address: "invitee@example.com", role: "admin")
    expect(ActionMailer::Base.deliveries.last).to have_attributes(
      to: ["invitee@example.com"],
      subject: "Join Pulse Studio on Pulse"
    )
  end

  it "limits an admin's invite role to member" do
    organization = create(:organization)
    admin = create(:organization_membership, organization:, role: :admin).user
    sign_in(admin)

    get settings_organization_members_path

    expect(response.body).to include("Member")
    expect(response.body).not_to include("Admin")
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
  end
end

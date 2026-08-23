require "rails_helper"

RSpec.describe OrganizationInvitationMailer do
  it "addresses the invitee and includes the acceptance URL" do
    invitation = create(:organization_invitation)
    mail = described_class.with(invitation:, token: "secure-token").invite

    expect(mail.to).to eq([invitation.email_address])
    expect(mail.subject).to eq("Join #{invitation.organization.name} on Pulse")
    expect(mail.body.encoded).to include(organization_invitation_url(token: "secure-token"))
  end
end

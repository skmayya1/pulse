class OrganizationInvitationMailer < ApplicationMailer
  def invite
    @invitation = params.fetch(:invitation)
    @organization = @invitation.organization
    @acceptance_url = organization_invitation_url(token: params.fetch(:token))

    mail(to: @invitation.email_address, subject: "Join #{@organization.name} on Pulse")
  end
end

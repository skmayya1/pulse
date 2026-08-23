class Settings::Organization::InvitationsController < ApplicationController
  def create
    organization = current_user.organizations.sole
    invitation = organization.organization_invitations.new(invitation_attributes.merge(invited_by: current_user))
    authorize invitation

    result = OrganizationInvitations::InviteService.call(
      organization:,
      invited_by: current_user,
      email_address: invitation.email_address,
      role: invitation.role
    )

    if result.success?
      redirect_to settings_organization_members_path, notice: "Invitation sent to #{result.invitation.email_address}."
    else
      redirect_to settings_organization_members_path, alert: invitation_error_message(result.error)
    end
  end

  private

  def invitation_attributes
    invitation = params.require(:organization_invitation)

    {
      email_address: invitation.fetch(:email_address),
      role: invitation.fetch(:role)
    }
  end

  def invitation_error_message(error)
    return "That person is already a member of this organization." if error == :already_member

    "We couldn't send that invitation. Please check the details and try again."
  end
end

class OrganizationInvitationsController < ApplicationController
  GENERIC_FAILURE = "This organization invitation is invalid or unavailable."

  allow_organizationless_access

  def show
    invitation = OrganizationInvitation.find_by_token(params[:token])
    return reject_invitation unless invitation

    authorize invitation, :accept?
    OrganizationInvitations::EnsureAcceptanceJob.set(wait: 2.minutes)
      .perform_later(current_user.id, invitation.id)

    result = OrganizationInvitations::AcceptService.call(invitation:, user: current_user)
    return reject_invitation unless result.success?

    redirect_to root_path, notice: "You joined #{invitation.organization.name}."
  rescue Pundit::NotAuthorizedError
    reject_invitation
  end

  private

  def reject_invitation
    redirect_to root_path, alert: GENERIC_FAILURE
  end
end

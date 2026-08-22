module OrganizationInvitations
  class EnsureAcceptanceJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound
    retry_on ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout,
      wait: :polynomially_longer,
      attempts: 3

    def perform(user_id, organization_invitation_id)
      user = User.find(user_id)
      invitation = OrganizationInvitation.find(organization_invitation_id)

      return if invitation.accepted_at.present? && membership_exists?(invitation, user)

      AcceptService.call(invitation:, user:)
    end

    private

    def membership_exists?(invitation, user)
      OrganizationMembership.exists?(organization: invitation.organization, user:)
    end
  end
end

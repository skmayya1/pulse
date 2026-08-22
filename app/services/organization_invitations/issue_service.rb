require "securerandom"

module OrganizationInvitations
  class IssueService
    LIFETIME = 7.days

    Result = Data.define(:invitation, :token, :error) do
      def success? = error.nil?
    end

    def self.call(organization:, invited_by:, email_address:, role:)
      new(organization:, invited_by:, email_address:, role:).call
    end

    def initialize(organization:, invited_by:, email_address:, role:)
      @organization = organization
      @invited_by = invited_by
      @email_address = email_address.to_s.strip.downcase
      @role = role.to_s
    end

    def call
      inviter_membership = organization.organization_memberships.find_by(user: invited_by)
      return failure(:unauthorized) unless allowed?(inviter_membership)
      return failure(:already_member) if existing_member?

      raw_token = SecureRandom.urlsafe_base64(32)

      organization.with_lock do
        pending_invitation&.update!(revoked_at: Time.current)
        invitation = organization.organization_invitations.create!(
          email_address:,
          invited_by:,
          role:,
          token_digest: Digest::SHA256.hexdigest(raw_token),
          expires_at: LIFETIME.from_now
        )

        Result.new(invitation:, token: raw_token, error: nil)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      failure(:invalid)
    end

    private

    attr_reader :organization, :invited_by, :email_address, :role

    def allowed?(membership)
      return false unless role.in?(OrganizationInvitation.roles)
      return false unless membership

      membership.owner? || (membership.admin? && role == "member")
    end

    def existing_member?
      organization.members.where("lower(users.email_address) = ?", email_address).exists?
    end

    def pending_invitation
      organization.organization_invitations
        .pending
        .find_by("lower(email_address) = ?", email_address)
    end

    def failure(error)
      Result.new(invitation: nil, token: nil, error:)
    end
  end
end

module OrganizationInvitations
  class AcceptService
    Result = Data.define(:invitation, :membership, :error) do
      def success? = error.nil?
    end

    def self.call(invitation:, user:)
      new(invitation:, user:).call
    end

    def initialize(invitation:, user:)
      @invitation = invitation
      @user = user
    end

    def call
      return failure unless invitation && user

      invitation.with_lock do
        return failure unless acceptable?

        membership = OrganizationMembership.find_or_initialize_by(
          organization: invitation.organization,
          user:
        )
        membership.role = invitation.role if membership.new_record?
        membership.save!
        invitation.update!(accepted_at: Time.current)

        Result.new(invitation:, membership:, error: nil)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      failure
    end

    private

    attr_reader :invitation, :user

    def acceptable?
      invitation.accepted_at.nil? &&
        invitation.revoked_at.nil? &&
        invitation.expires_at > Time.current &&
        invitation.email_address == user.email_address
    end

    def failure
      Result.new(invitation:, membership: nil, error: :invalid)
    end
  end
end

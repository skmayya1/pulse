module OrganizationInvitations
  class InviteService
    Result = Data.define(:invitation, :error) do
      def success? = error.nil?
    end

    def self.call(organization:, invited_by:, email_address:, role:)
      new(organization:, invited_by:, email_address:, role:).call
    end

    def initialize(organization:, invited_by:, email_address:, role:)
      @organization = organization
      @invited_by = invited_by
      @email_address = email_address
      @role = role
    end

    def call
      issue_result = IssueService.call(organization:, invited_by:, email_address:, role:)
      return Result.new(invitation: nil, error: issue_result.error) unless issue_result.success?

      OrganizationInvitationMailer.with(invitation: issue_result.invitation, token: issue_result.token).invite.deliver_now
      Result.new(invitation: issue_result.invitation, error: nil)
    rescue
      issue_result&.invitation&.update!(revoked_at: Time.current)
      Result.new(invitation: nil, error: :delivery_failed)
    end

    private

    attr_reader :organization, :invited_by, :email_address, :role
  end
end

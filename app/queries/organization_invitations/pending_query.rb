module OrganizationInvitations
  class PendingQuery
    def self.call(scope:, organization:)
      scope
        .where(organization:)
        .pending
        .includes(:invited_by)
        .order(created_at: :desc)
    end
  end
end

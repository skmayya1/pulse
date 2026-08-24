module OrganizationMemberships
  class ListQuery
    def self.call(scope:, organization:)
      scope
        .where(organization:)
        .includes(:user)
        .order(:created_at)
    end
  end
end

module ProviderConnections
  class OrganizationQuery
    def initialize(scope:, organization:)
      @scope = scope.where(organization:)
    end

    def ordered(channel: nil)
      relation = channel ? scope.where(channel:) : scope
      relation.order(created_at: :desc)
    end

    def visible
      ordered.where.not(status: :disconnected)
    end

    def active_counts
      scope.active.group(:channel_id).count
    end

    def reauthorization_channel_ids
      scope.needs_reauthorization.pluck(:channel_id).to_set
    end

    private

    attr_reader :scope
  end
end

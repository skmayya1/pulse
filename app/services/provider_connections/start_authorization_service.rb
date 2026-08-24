module ProviderConnections
  class StartAuthorizationService
    Result = Data.define(:authorization_url, :error) do
      def success? = error.nil?
    end

    def self.call(user:, organization:, channel:, flow_store: OauthFlowStore.new, registry: Providers::Registry)
      new(user:, organization:, channel:, flow_store:, registry:).call
    end

    def initialize(user:, organization:, channel:, flow_store:, registry:)
      @user = user
      @organization = organization
      @channel = channel
      @flow_store = flow_store
      @registry = registry
    end

    def call
      membership = user.organization_memberships.find_by(organization:)
      return failure(:invalid) unless channel&.enabled? && membership&.role_at_least?(:admin)

      client = registry.for(channel.provider)
      state = flow_store.issue_authorization(
        user_id: user.id,
        organization_id: organization.id,
        channel_id: channel.id
      )

      Result.new(authorization_url: client.authorization_url(state:, channel:), error: nil)
    rescue Providers::ConfigurationError
      failure(:unavailable)
    end

    private

    attr_reader :user, :organization, :channel, :flow_store, :registry

    def failure(error)
      Result.new(authorization_url: nil, error:)
    end
  end
end

module ProviderConnections
  class CompleteAuthorizationService
    Result = Data.define(:connections, :selection_token, :channel, :error) do
      def success? = error.nil?
      def selection_required? = selection_token.present?
    end

    def self.call(user:, provider:, state:, code:, provider_error: nil, flow_store: OauthFlowStore.new, registry: Providers::Registry)
      new(user:, provider:, state:, code:, provider_error:, flow_store:, registry:).call
    end

    def initialize(user:, provider:, state:, code:, provider_error:, flow_store:, registry:)
      @user = user
      @provider = provider.to_s
      @state = state
      @code = code
      @provider_error = provider_error
      @flow_store = flow_store
      @registry = registry
    end

    def call
      flow = flow_store.consume_authorization(state)
      return failure(:invalid) unless valid_flow?(flow)

      channel = Channel.enabled.find_by(id: flow.fetch("channel_id"))
      return failure(:invalid) unless channel&.provider == provider

      client = registry.for(provider)
      token_set = client.exchange_code(code:)
      candidates = client.discover_accounts(token_set:, channel:)
      return failure(:no_accounts, channel:) if candidates.empty?

      return connect(flow, channel, candidates.first) if candidates.one?

      selection_token = flow_store.issue_selection(selection_payload(flow, candidates))
      Result.new(connections: [], selection_token:, channel:, error: nil)
    rescue KeyError, ActiveRecord::RecordNotFound, Providers::AuthorizationError, Providers::RequestError
      failure(:invalid)
    rescue Providers::ConfigurationError
      failure(:unavailable)
    rescue Providers::TransientError
      failure(:temporary)
    end

    private

    attr_reader :user, :provider, :state, :code, :provider_error, :flow_store, :registry

    def valid_flow?(flow)
      membership = user.organization_memberships.find_by(organization_id: flow&.fetch("organization_id", nil))

      provider_error.blank? && code.present? && flow.present? &&
        flow["user_id"] == user.id &&
        membership&.role_at_least?(:admin)
    end

    def connect(flow, channel, candidate)
      organization = user.organizations.find(flow.fetch("organization_id"))
      result = ConnectService.call(user:, organization:, channel:, candidates: candidate)
      return failure(result.error, channel:) unless result.success?

      Result.new(connections: result.connections, selection_token: nil, channel:, error: nil)
    end

    def selection_payload(flow, candidates)
      {
        "user_id" => flow.fetch("user_id"),
        "organization_id" => flow.fetch("organization_id"),
        "channel_id" => flow.fetch("channel_id"),
        "candidates" => candidates.map { |candidate| serialize(candidate) }
      }
    end

    def serialize(candidate)
      candidate.to_h.transform_values do |value|
        value.is_a?(Time) ? value.iso8601(6) : value
      end.transform_keys(&:to_s)
    end

    def failure(error, channel: nil)
      Result.new(connections: [], selection_token: nil, channel:, error:)
    end
  end
end

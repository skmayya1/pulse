module ProviderConnections
  class SelectionService
    Candidate = Data.define(:provider_account_id, :name, :handle, :avatar_url)
    Result = Data.define(:channel, :candidates, :connections, :error) do
      def success? = error.nil?
    end

    class << self
      def load(user:, channel:, token:, flow_store: OauthFlowStore.new)
        new(user:, channel:, token:, selected_ids: nil, flow_store:).load
      end

      def call(user:, channel:, token:, selected_ids:, flow_store: OauthFlowStore.new)
        new(user:, channel:, token:, selected_ids:, flow_store:).call
      end
    end

    def initialize(user:, channel:, token:, selected_ids:, flow_store:)
      @user = user
      @channel = channel
      @token = token
      @selected_ids = Array(selected_ids).map(&:to_s).uniq
      @flow_store = flow_store
    end

    def load
      flow = flow_store.read_selection(token)
      return failure unless valid_flow?(flow)

      Result.new(
        channel:,
        candidates: flow.fetch("candidates").map { |candidate| display_candidate(candidate) },
        connections: [],
        error: nil
      )
    rescue KeyError
      failure
    end

    def call
      flow = flow_store.consume_selection(token)
      return failure unless valid_flow?(flow) && selected_ids.present?

      candidates = flow.fetch("candidates").index_by { |candidate| candidate.fetch("provider_account_id").to_s }
      return failure unless (selected_ids - candidates.keys).empty?

      organization = user.organizations.find(flow.fetch("organization_id"))
      result = ConnectService.call(
        user:,
        organization:,
        channel:,
        candidates: selected_ids.map { |id| deserialize(candidates.fetch(id)) }
      )
      return failure(result.error) unless result.success?

      Result.new(channel:, candidates: [], connections: result.connections, error: nil)
    rescue KeyError, ActiveRecord::RecordNotFound
      failure
    end

    private

    attr_reader :user, :channel, :token, :selected_ids, :flow_store

    def valid_flow?(flow)
      membership = user.organization_memberships.find_by(organization_id: flow&.fetch("organization_id", nil))

      flow.present? &&
        flow["user_id"] == user.id &&
        flow["channel_id"] == channel.id &&
        membership&.role_at_least?(:admin)
    end

    def display_candidate(candidate)
      Candidate.new(
        provider_account_id: candidate.fetch("provider_account_id"),
        name: candidate.fetch("name"),
        handle: candidate["handle"],
        avatar_url: candidate["avatar_url"]
      )
    end

    def deserialize(candidate)
      expires_at = Time.iso8601(candidate["expires_at"]) if candidate["expires_at"].present?

      Providers::AccountCandidate.new(
        **candidate.symbolize_keys.merge(expires_at:)
      )
    end

    def failure(error = :invalid)
      Result.new(channel:, candidates: [], connections: [], error:)
    end
  end
end

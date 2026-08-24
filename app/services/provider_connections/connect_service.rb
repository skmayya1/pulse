module ProviderConnections
  class ConnectService
    Result = Data.define(:connections, :error) do
      def success? = error.nil?
    end

    class ConnectionConflict < StandardError; end

    def self.call(user:, organization:, channel:, candidates:)
      new(user:, organization:, channel:, candidates: Array(candidates)).call
    end

    def initialize(user:, organization:, channel:, candidates:)
      @user = user
      @organization = organization
      @channel = channel
      @candidates = candidates
    end

    def call
      membership = user.organization_memberships.find_by(organization:)
      return failure(:invalid) if candidates.empty? || !membership&.role_at_least?(:admin)

      connections = ProviderConnection.transaction do
        candidates.map { |candidate| persist(candidate) }
      end
      Result.new(connections:, error: nil)
    rescue ActiveRecord::RecordInvalid
      failure(:invalid)
    rescue ActiveRecord::RecordNotUnique, ConnectionConflict
      failure(:already_connected)
    end

    private

    attr_reader :user, :organization, :channel, :candidates

    def persist(candidate)
      connection = ProviderConnection.lock.find_or_initialize_by(
        channel:,
        provider_account_id: candidate.provider_account_id
      )
      raise ConnectionConflict if connection.persisted? && connection.organization_id != organization.id

      connection.assign_attributes(
        organization:,
        connected_by: user,
        provider_identity_id: candidate.provider_identity_id,
        name: candidate.name,
        handle: candidate.handle,
        avatar_url: candidate.avatar_url,
        access_token: candidate.access_token,
        refresh_token: candidate.refresh_token.presence || connection.refresh_token,
        token_expires_at: candidate.expires_at,
        scopes: candidate.scopes,
        status: :connected,
        metadata: candidate.metadata,
        connected_at: Time.current,
        last_synced_at: Time.current,
        disconnected_at: nil
      )
      connection.save!
      connection
    end

    def failure(error)
      Result.new(connections: [], error:)
    end
  end
end

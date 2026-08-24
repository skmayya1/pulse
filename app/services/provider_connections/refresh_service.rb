module ProviderConnections
  class RefreshService
    Result = Data.define(:connection, :error) do
      def success? = error.nil?
    end

    def self.call(connection:, registry: Providers::Registry)
      new(connection:, registry:).call
    end

    def initialize(connection:, registry:)
      @connection = connection
      @registry = registry
    end

    def call
      connection.with_lock do
        return Result.new(connection:, error: nil) unless connection.active?

        refreshed = registry.for(connection.provider).refresh(token_set: current_token_set)
        connection.update!(
          access_token: refreshed.access_token,
          refresh_token: refreshed.refresh_token.presence || connection.refresh_token,
          token_expires_at: refreshed.expires_at,
          scopes: refreshed.scopes.presence || connection.scopes,
          provider_identity_id: refreshed.provider_identity_id.presence || connection.provider_identity_id,
          status: :connected
        )
      end

      Result.new(connection:, error: nil)
    rescue Providers::AuthorizationError, Providers::RequestError, Providers::ConfigurationError
      mark_for_reauthorization
      Result.new(connection:, error: :needs_reauthorization)
    end

    private

    attr_reader :connection, :registry

    def current_token_set
      Providers::TokenSet.new(
        access_token: connection.access_token,
        refresh_token: connection.refresh_token,
        expires_at: connection.token_expires_at,
        scopes: connection.scopes,
        provider_identity_id: connection.provider_identity_id,
        metadata: connection.metadata
      )
    end

    def mark_for_reauthorization
      connection.with_lock do
        connection.update!(status: :needs_reauthorization) unless connection.disconnected?
      end
    end
  end
end

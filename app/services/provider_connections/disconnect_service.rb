module ProviderConnections
  class DisconnectService
    Result = Data.define(:connection, :error) do
      def success? = error.nil?
    end

    def self.call(connection:, user:)
      new(connection:, user:).call
    end

    def initialize(connection:, user:)
      @connection = connection
      @user = user
    end

    def call
      membership = user.organization_memberships.find_by(organization: connection.organization)
      return Result.new(connection:, error: :invalid) unless membership&.role_at_least?(:admin)

      connection.with_lock do
        connection.update!(
          status: :disconnected,
          disconnected_at: Time.current,
          access_token: nil,
          refresh_token: nil,
          token_expires_at: nil
        )
      end

      Result.new(connection:, error: nil)
    rescue ActiveRecord::RecordInvalid
      Result.new(connection:, error: :invalid)
    end

    private

    attr_reader :connection, :user
  end
end

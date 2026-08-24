module ProviderConnections
  class RefreshJob < ApplicationJob
    queue_as :default

    retry_on Providers::TransientError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveRecord::RecordNotFound

    def perform(provider_connection_id)
      connection = ProviderConnection.find(provider_connection_id)
      RefreshService.call(connection:)
    end
  end
end

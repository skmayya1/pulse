module ProviderConnections
  class EnqueueRefreshesJob < ApplicationJob
    queue_as :low

    def perform
      ProviderConnection.active
        .where(token_expires_at: ..30.minutes.from_now)
        .find_each do |connection|
          RefreshJob.perform_later(connection.id)
        end
    end
  end
end

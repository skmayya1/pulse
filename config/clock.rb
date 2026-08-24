require_relative "boot"
require_relative "environment"

require "clockwork"

module Clockwork
  every(1.day, "sessions.prune", at: "03:00") do
    Sessions::PruneExpiredJob.perform_later
  end

  every(15.minutes, "provider_connections.refresh") do
    ProviderConnections::EnqueueRefreshesJob.perform_later
  end
end

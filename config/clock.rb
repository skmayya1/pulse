require_relative "boot"
require_relative "environment"

require "clockwork"

module Clockwork
  every(1.day, "sessions.prune", at: "03:00") do
    Sessions::PruneExpiredJob.perform_later
  end
end

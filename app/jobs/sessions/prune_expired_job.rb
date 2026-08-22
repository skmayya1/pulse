module Sessions
  class PruneExpiredJob < ApplicationJob
    queue_as :low

    def perform
      Session.prune_expired!
    end
  end
end

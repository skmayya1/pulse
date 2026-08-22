class ApplicationJob < ActiveJob::Base
  around_perform do |_job, block|
    Current.clear
    block.call
  ensure
    Current.clear
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end

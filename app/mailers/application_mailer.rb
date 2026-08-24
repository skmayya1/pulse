class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Pulse <hello@pulse.local>")
  default reply_to: ENV.fetch("MAILER_REPLY_TO", "Pulse <hello@pulse.local>")
  layout "mailer"
end

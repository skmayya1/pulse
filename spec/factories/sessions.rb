FactoryBot.define do
  factory :session do
    user
    sequence(:token_digest) { |number| Digest::SHA256.hexdigest("token-#{number}") }
    ip_address { "127.0.0.1" }
    user_agent { "RSpec" }
    last_active_at { Time.current }
    expires_at { 30.days.from_now }
  end
end

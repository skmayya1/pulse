FactoryBot.define do
  factory :provider_connection do
    organization
    channel
    association :connected_by, factory: :user
    sequence(:provider_account_id) { |number| "account-#{number}" }
    sequence(:provider_identity_id) { |number| "provider-user-#{number}" }
    sequence(:name) { |number| "Pulse Account #{number}" }
    handle { "pulse" }
    avatar_url { "https://example.com/avatar.png" }
    access_token { "access-token" }
    refresh_token { "refresh-token" }
    scopes { ["pages_show_list"] }
    status { :connected }
    metadata { {} }
    connected_at { Time.current }
  end
end

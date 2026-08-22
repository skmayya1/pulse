FactoryBot.define do
  factory :user do
    sequence(:email_address) { |number| "creator#{number}@example.com" }
    verified_at { Time.current }
  end
end

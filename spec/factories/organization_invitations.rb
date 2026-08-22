FactoryBot.define do
  factory :organization_invitation do
    organization
    association :invited_by, factory: :user
    sequence(:email_address) { |number| "invited#{number}@example.com" }
    role { :member }
    sequence(:token_digest) { |number| Digest::SHA256.hexdigest("invitation-#{number}") }
    expires_at { 7.days.from_now }
  end
end

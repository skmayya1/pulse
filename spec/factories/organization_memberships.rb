FactoryBot.define do
  factory :organization_membership do
    organization
    user
    role { :member }
  end
end

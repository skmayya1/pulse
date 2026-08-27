FactoryBot.define do
  factory :post do
    organization
    association :created_by, factory: :user
  end
end

FactoryBot.define do
  factory :post do
    organization
    association :created_by, factory: :user
    caption { "Draft caption" }
  end
end

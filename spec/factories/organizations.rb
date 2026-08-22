FactoryBot.define do
  factory :organization do
    sequence(:name) { |number| "Organization #{number}" }
    time_zone { "UTC" }
  end
end

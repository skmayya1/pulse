FactoryBot.define do
  factory :channel do
    sequence(:key) { |number| "channel_#{number}" }
    sequence(:name) { |number| "Pulse Channel #{number}" }
    provider { :meta }
    icon { "ti-brand-meta" }
    sequence(:position)
    enabled { true }
    configuration { {} }
  end
end

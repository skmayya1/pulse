FactoryBot.define do
  factory :media do
    uploadable factory: :organization
    association :uploaded_by, factory: :user
    kind { :image }
    metadata { {} }

    after(:build) do |media|
      next if media.file.attached?

      media.file.attach(
        io: Rails.root.join("spec/fixtures/files/pixel.png").open,
        filename: "pixel.png",
        content_type: "image/png"
      )
    end
  end
end

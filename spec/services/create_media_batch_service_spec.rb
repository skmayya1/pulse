require "rails_helper"

RSpec.describe CreateMediaBatchService do
  it "uploads multiple files in one batch" do
    organization = create(:organization)
    user = create(:user)

    result = described_class.call(
      uploadable: organization,
      uploaded_by: user,
      files: [
        fixture_file("pixel.png", "image/png"),
        fixture_file("pixel.png", "image/png")
      ]
    )

    expect(result).to be_success
    expect(result.media_records.size).to eq(2)
    expect(organization.media.count).to eq(2)
  end

  it "applies a custom filename only when a single file is uploaded" do
    organization = create(:organization)
    user = create(:user)

    result = described_class.call(
      uploadable: organization,
      uploaded_by: user,
      files: [fixture_file("pixel.png", "image/png")],
      filename: "Hero.png"
    )

    expect(result.media_records.first.filename).to eq("Hero.png")
  end

  it "rejects more than five files without creating any records" do
    files = Array.new(6) { fixture_file("pixel.png", "image/png") }

    result = described_class.call(
      uploadable: create(:organization),
      uploaded_by: create(:user),
      files:
    )

    expect(result.error).to eq(:too_many)
    expect(result.media_records).to be_empty
    expect(Media.count).to eq(0)
  end

  def fixture_file(filename, content_type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/#{filename}"), content_type)
  end
end

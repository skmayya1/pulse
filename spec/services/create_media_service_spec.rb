require "rails_helper"

RSpec.describe CreateMediaService do
  it "uploads media using the original filename by default" do
    organization = create(:organization)
    user = create(:user)

    result = described_class.call(
      uploadable: organization,
      uploaded_by: user,
      file: fixture_file("pixel.png", "image/png")
    )

    expect(result).to be_success
    expect(result.media).to have_attributes(
      uploadable: organization,
      uploaded_by: user,
      kind: "image",
      filename: "pixel.png"
    )
    expect(result.media.file).to be_attached
  end

  it "uses an overridden filename when provided" do
    organization = create(:organization)
    user = create(:user)

    result = described_class.call(
      uploadable: organization,
      uploaded_by: user,
      file: fixture_file("pixel.png", "image/png"),
      filename: "Hero banner.png"
    )

    expect(result.media.filename).to eq("Hero banner.png")
  end

  it "rejects a file that is not an allowed type" do
    result = described_class.call(
      uploadable: create(:organization),
      uploaded_by: create(:user),
      file: fixture_file("notes.txt", "text/plain")
    )

    expect(result.error).to eq(:invalid)
    expect(result.media).not_to be_persisted
  end

  def fixture_file(filename, content_type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/#{filename}"), content_type)
  end
end

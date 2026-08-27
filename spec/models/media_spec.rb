require "rails_helper"

RSpec.describe Media do
  it "belongs to a polymorphic uploadable owner" do
    organization = create(:organization)
    user = create(:user)
    org_media = create(:media, uploadable: organization, uploaded_by: user)
    user_media = create(:media, uploadable: user, uploaded_by: user)

    expect(org_media.uploadable).to eq(organization)
    expect(user_media.uploadable).to eq(user)
    expect(organization.media).to contain_exactly(org_media)
    expect(user.media).to contain_exactly(user_media)
    expect(user.uploaded_media).to contain_exactly(org_media, user_media)
  end

  it "accepts image and video kinds and rejects unknown ones" do
    video = build(:media, kind: :video)
    video.file.attach(io: StringIO.new("fake-mp4"), filename: "clip.mp4", content_type: "video/mp4")

    expect(build(:media, kind: :image)).to be_valid
    expect(video).to be_valid
    expect(build(:media, kind: :unknown)).not_to be_valid
  end

  it "requires an attached file" do
    media = build(:media)
    media.file.detach

    expect(media).not_to be_valid
    expect(media.errors[:file]).to include("must be attached")
  end

  it "rejects image content types that are not allowed" do
    media = build(:media)
    media.file.attach(
      io: StringIO.new("not-an-image"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    expect(media).not_to be_valid
    expect(media.errors[:file]).to include("is not an allowed type")
  end

  it "rejects images that exceed the size limit" do
    media = build(:media)
    allow(media.file).to receive_messages(attached?: true, filename: "huge.png", content_type: "image/png", byte_size: 11.megabytes)

    expect(media).not_to be_valid
    expect(media.errors[:file]).to include("is too large")
  end

  it "copies blob metadata onto the record" do
    media = create(:media)

    expect(media).to have_attributes(
      filename: "pixel.png",
      content_type: "image/png",
      byte_size: a_value > 0
    )
    expect(media.file).to be_attached
    expect(media.file.variant(:thumb)).to be_present
  end

  it "keeps an explicit filename instead of the blob name" do
    media = build(:media, filename: "Hero.png")

    expect(media).to be_valid
    expect(media.filename).to eq("Hero.png")
  end
end

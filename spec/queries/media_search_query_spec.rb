require "rails_helper"

RSpec.describe MediaSearchQuery do
  it "filters an organization's media by filename" do
    organization = create(:organization)
    matching = create(:media, uploadable: organization, filename: "hero-banner.png")
    create(:media, uploadable: organization, filename: "outro.mp4")
    create(:media, filename: "hero-banner.png")

    result = described_class.new(
      scope: Media.all,
      uploadable: organization,
      query: "hero"
    ).call

    expect(result.records).to eq([matching])
    expect(result.next_cursor).to be_nil
  end

  it "returns 20 records and a cursor for the next page" do
    organization = create(:organization)
    records = create_list(:media, 21, uploadable: organization)
    newest = records.sort_by { |media| [media.created_at, media.id] }.last(20).reverse

    result = described_class.new(scope: Media.all, uploadable: organization).call

    expect(result.records).to eq(newest)
    expect(result.next_cursor).to be_present

    remaining = described_class.new(
      scope: Media.all,
      uploadable: organization,
      cursor: result.next_cursor
    ).call

    expect(remaining.records.size).to eq(1)
    expect(remaining.next_cursor).to be_nil
  end
end

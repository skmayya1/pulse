require "rails_helper"

RSpec.describe "Media" do
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  it "does not load library records on the initial media request" do
    membership = create(:organization_membership)
    included = create(:media, uploadable: membership.organization, filename: "campaign.png")
    sign_in(membership.user)

    get media_index_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(included.filename)
  end

  it "lists organization media and hides other organizations' files" do
    membership = create(:organization_membership)
    included = create(:media, uploadable: membership.organization, filename: "campaign.png")
    create(:media, filename: "secret.png")
    sign_in(membership.user)

    get media_index_path, headers: {"Turbo-Frame" => "media_list"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(included.filename)
    expect(response.body).not_to include("secret.png")
  end

  it "filters media by filename" do
    membership = create(:organization_membership)
    create(:media, uploadable: membership.organization, filename: "hero.png")
    create(:media, uploadable: membership.organization, filename: "outro.mp4")
    sign_in(membership.user)

    get media_index_path, params: {q: "hero"}, headers: {"Turbo-Frame" => "media_list"}

    expect(response.body).to include("hero.png")
    expect(response.body).not_to include("outro.mp4")
  end

  it "returns the next page of media for a cursor" do
    membership = create(:organization_membership)
    records = Array.new(21) do |index|
      create(:media, uploadable: membership.organization, filename: "file-#{index}.png")
    end
    sign_in(membership.user)

    get media_index_path, headers: {"Turbo-Frame" => "media_list"}

    first_page = MediaSearchQuery.new(scope: Media.all, uploadable: membership.organization).call
    remaining = records.map(&:filename) - first_page.records.map(&:filename)

    expect(response.body).to include(*first_page.records.map(&:filename))
    expect(response.body).not_to include(*remaining)

    get media_index_path,
      params: {cursor: first_page.next_cursor},
      headers: {"Turbo-Frame" => "media_list"}

    expect(response.body).to include(*remaining)
  end

  it "uploads media for the current organization" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    expect {
      post media_index_path, params: {
        media: {
          files: [fixture_file_upload("pixel.png", "image/png")],
          filename: "Launch.png"
        }
      }
    }.to change(Media, :count).by(1)

    expect(response).to redirect_to(media_index_path)
    expect(Media.last).to have_attributes(
      uploadable: membership.organization,
      uploaded_by: membership.user,
      filename: "Launch.png"
    )
  end

  it "uploads up to five files in one request" do
    membership = create(:organization_membership)
    sign_in(membership.user)
    files = Array.new(2) { fixture_file_upload("pixel.png", "image/png") }

    expect {
      post media_index_path, params: {media: {files:}}
    }.to change(Media, :count).by(2)

    expect(response).to redirect_to(media_index_path)
  end

  it "rejects more than five files" do
    membership = create(:organization_membership)
    sign_in(membership.user)
    files = Array.new(6) { fixture_file_upload("pixel.png", "image/png") }

    expect {
      post media_index_path, params: {media: {files:}}
    }.not_to change(Media, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("limited to 5")
  end

  def sign_in(user)
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
    allow(SecureRandom).to receive(:random_number).and_call_original
  end
end

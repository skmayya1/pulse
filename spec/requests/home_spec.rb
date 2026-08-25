require "rails_helper"

RSpec.describe "Home" do
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
  end

  it "renders the app sidebar for an organization member" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    get root_path

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)

    expect(response.body).to include(
      membership.user.email_address,
      membership.organization.name,
      "Dark mode",
      "Settings",
      "Sign out"
    )
    expect(document.at_css(".dropdown.dropdown-top")).to be_present
    expect(document.at_css(".dropdown-content")).to be_present
    expect(document.at_css("dialog#sign_out_dialog.modal")).to be_present
    expect(document.at_css("dialog#sign_out_dialog .modal-backdrop")).to be_present
    expect(document.at_css("dialog#sign_out_dialog .modal-action")).to be_present
    expect(response.body).to include("Close")
    expect(document.at_css("dialog#sign_out_dialog .btn-circle")).not_to be_present
    expect(document.at_css("input.toggle[data-set-theme][value=dark]")).to be_present
    expect(document.at_css("nav[aria-label='Main navigation']")).to be_present
    expect(response.body).to include(
      "New post",
      "Publish",
      "Calendar",
      "Posts",
      "Approvals",
      "Campaigns",
      "Engage",
      "Inbox",
      "Library",
      "Media",
      "Insights",
      "Analytics"
    )
    expect(response.body).not_to include("Your organizations")
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
  end
end

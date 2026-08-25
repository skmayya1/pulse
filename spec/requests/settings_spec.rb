require "rails_helper"

RSpec.describe "Settings" do
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

  it "requires an organization membership" do
    sign_in(create(:user))

    get settings_path

    expect(response).to redirect_to(new_organization_path)
  end

  it "redirects the settings root to profile" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    get settings_path

    expect(response).to redirect_to(settings_profile_path)
  end

  it "renders each settings section for an organization member" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    [
      settings_profile_path,
      settings_preferences_path,
      settings_notifications_path,
      settings_organization_general_path,
      settings_organization_channels_path,
      settings_organization_members_path
    ].each do |path|
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Settings")
    end
  end

  it "renders desktop navigation and the mobile settings drawer" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    get settings_profile_path

    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#settings-drawer.drawer-toggle")).to be_present
    expect(response.body).to include("drawer-side", "Open settings navigation")
    expect(document.css("nav[aria-label='Settings navigation']").size).to eq(2)
  end

  it "renders enabled channels in the organization channel catalog" do
    membership = create(:organization_membership)
    instagram = create(
      :channel,
      key: "instagram",
      name: "Instagram",
      provider: :instagram,
      icon: "channels/instagram.png",
      position: 1
    )
    create(:channel, key: "disabled", enabled: false)
    sign_in(membership.user)

    get settings_organization_channels_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(instagram.name, "Connect")
    expect(response.body).to include("channels/instagram")
    expect(response.body).not_to include("collapse")
    expect(response.body).not_to include("Manage")
    expect(response.body).not_to include("Pulse Channel")
  end

  it "renders organization details as read-only for members" do
    membership = create(:organization_membership, role: :member)
    sign_in(membership.user)

    get settings_organization_general_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(membership.organization.name, "Time zone")
    expect(response.body).to include("disabled")
    expect(response.body).not_to include("Save changes")
  end

  it "allows organization admins to update general settings" do
    membership = create(:organization_membership, role: :admin)
    sign_in(membership.user)

    patch settings_organization_general_path, params: {
      organization: {name: "Pulse Studio", time_zone: "Chennai"}
    }

    expect(response).to redirect_to(settings_organization_general_path)
    expect(membership.organization.reload).to have_attributes(
      name: "Pulse Studio",
      time_zone: "Chennai"
    )
  end

  it "renders validation errors without updating the organization" do
    membership = create(:organization_membership, role: :owner)
    sign_in(membership.user)

    patch settings_organization_general_path, params: {
      organization: {name: "", time_zone: "UTC"}
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Name can&#39;t be blank")
  end

  it "renders the profile form for the signed-in user" do
    membership = create(:organization_membership)
    membership.user.update!(name: "Ada Lovelace")
    sign_in(membership.user)

    get settings_profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Profile", "Ada Lovelace", membership.user.email_address, "Save changes")
    expect(response.body).to include("input", "fieldset")
    expect(response.body).not_to include("This settings section is ready for its first controls.")
  end

  it "updates the signed-in user's profile name" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    patch settings_profile_path, params: {
      user: {name: "Ada Lovelace"}
    }

    expect(response).to redirect_to(settings_profile_path)
    expect(membership.user.reload.name).to eq("Ada Lovelace")
  end

  it "renders validation errors without updating the profile" do
    membership = create(:organization_membership)
    membership.user.update!(name: "Ada")
    sign_in(membership.user)

    patch settings_profile_path, params: {
      user: {name: "A" * 101}
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Name is too long")
    expect(membership.user.reload.name).to eq("Ada")
  end

  it "renders the theme-change appearance controls on preferences" do
    membership = create(:organization_membership)
    sign_in(membership.user)

    get settings_preferences_path

    document = Nokogiri::HTML(response.body)
    buttons = document.css("[data-set-theme]")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Preferences", "Appearance")
    expect(response.body).to include("cdn.jsdelivr.net/npm/theme-change@3.0.4/index.js")
    expect(buttons.pluck("data-set-theme")).to eq(["", "light", "dark"])
    expect(response.body).not_to include("Save changes")
    expect(response.body).not_to include("This settings section is ready for its first controls.")
  end

  def sign_in(user)
    Authentication::OtpService.send_code(email_address: user.email_address, ip_address: "127.0.0.1")
    post login_path, params: {
      authentication: {email_address: user.email_address, code: "123456"}
    }
  end
end

require "rails_helper"

RSpec.describe ProviderConnection do
  it "accepts supported connection statuses and rejects unknown ones" do
    expect(build(:provider_connection, status: :connected)).to be_valid
    expect(build(:provider_connection, status: :needs_reauthorization)).to be_valid
    expect(build(:provider_connection, status: :disconnected)).to be_valid
    expect(build(:provider_connection, status: :unknown)).not_to be_valid
  end

  it "derives its provider from the catalog channel" do
    connection = build(:provider_connection, channel: build(:channel, provider: :youtube))

    expect(connection.provider).to eq("youtube")
  end

  it "encrypts credentials and excludes them from serialization" do
    connection = create(:provider_connection, access_token: "secret-access-token", refresh_token: "secret-refresh-token")
    ciphertext = described_class.connection.select_value(
      described_class.sanitize_sql_array(["SELECT access_token FROM provider_connections WHERE id = ?", connection.id])
    )

    expect(ciphertext).not_to eq("secret-access-token")
    expect(connection.reload.access_token).to eq("secret-access-token")
    expect(connection.serializable_hash).not_to include("access_token", "refresh_token")
  end

  it "allows one organization to connect multiple accounts for the same channel" do
    channel = create(:channel)
    organization = create(:organization)
    create(:provider_connection, organization:, channel:, provider_account_id: "first-account")

    expect(build(:provider_connection, organization:, channel:, provider_account_id: "second-account")).to be_valid
  end

  it "allows Meta connections to share an OAuth identity" do
    channel = create(:channel, provider: :meta)
    organization = create(:organization)
    create(:provider_connection, organization:, channel:, provider_identity_id: "meta-user", provider_account_id: "instagram-account")

    expect(build(:provider_connection, organization:, channel:, provider_identity_id: "meta-user", provider_account_id: "facebook-page")).to be_valid
  end

  it "identifies external accounts globally within a catalog channel" do
    connection = create(:provider_connection, provider_account_id: "instagram-account")

    duplicate = build(:provider_connection, channel: connection.channel, provider_account_id: connection.provider_account_id)

    expect(duplicate).not_to be_valid
  end
end

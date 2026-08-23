require "rails_helper"

RSpec.describe "Channel and provider connection schema" do
  it "has unique indexes for catalog keys and connected external accounts" do
    connection = ActiveRecord::Base.connection

    expect(connection.indexes(:channels).map(&:name)).to include("index_channels_on_key")
    expect(connection.indexes(:provider_connections).map(&:name)).to include(
      "index_provider_connections_on_channel_and_provider_account"
    )
  end
end

require "rails_helper"

RSpec.describe Providers::Configuration do
  around do |example|
    keys = %w[
      APP_HOST INSTAGRAM_CLIENT_ID INSTAGRAM_CLIENT_SECRET
      META_CLIENT_ID META_CLIENT_SECRET META_CONFIG_ID META_API_VERSION
    ]
    original = ENV.to_h.slice(*keys)
    keys.each { |key| ENV.delete(key) }
    example.run
  ensure
    keys.each do |key|
      original.key?(key) ? ENV[key] = original.fetch(key) : ENV.delete(key)
    end
  end

  it "treats Instagram as configured when the Instagram app credentials are present" do
    ENV["APP_HOST"] = "https://pulse.test"
    ENV["INSTAGRAM_CLIENT_ID"] = "instagram-client"
    ENV["INSTAGRAM_CLIENT_SECRET"] = "instagram-secret"

    expect(described_class.configured?(:instagram)).to be(true)
    expect(described_class.for(:instagram)).to have_attributes(client_id: "instagram-client")
  end

  it "requires a Login for Business configuration id before Facebook is available" do
    ENV["APP_HOST"] = "https://pulse.test"
    ENV["META_CLIENT_ID"] = "meta-client"
    ENV["META_CLIENT_SECRET"] = "meta-secret"

    expect(described_class.configured?(:meta)).to be(false)

    ENV["META_CONFIG_ID"] = "meta-config"

    expect(described_class.configured?(:meta)).to be(true)
    expect(described_class.for(:meta)).to have_attributes(config_id: "meta-config", api_version: "v24.0")
  end
end

require "rails_helper"

RSpec.describe Authentication::OtpService do
  include ActiveSupport::Testing::TimeHelpers

  let(:email_address) { "creator@example.com" }
  let(:ip_address) { "127.0.0.1" }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    travel_back
    Rails.cache = original_cache
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123_456)
  end

  it "generates six numeric digits" do
    result = described_class.send_code(email_address:, ip_address:)
    expect(result).to be_success
    expect(result).to be_sent
    expect(described_class.verify_code(email_address:, code: "123456", ip_address:)).to be_success
  end

  it "accepts a code only once" do
    described_class.send_code(email_address:, ip_address:)

    expect(described_class.verify_code(email_address:, code: "123456", ip_address:)).to be_success
    expect(described_class.verify_code(email_address:, code: "123456", ip_address:)).not_to be_success
  end

  it "expires codes after ten minutes" do
    described_class.send_code(email_address:, ip_address:)

    travel 11.minutes

    expect(described_class.verify_code(email_address:, code: "123456", ip_address:)).not_to be_success
  end

  it "enforces a sixty-second resend cooldown" do
    described_class.send_code(email_address:, ip_address:)

    expect(described_class.send_code(email_address:, ip_address:).error).to eq(:cooldown)
    travel 61.seconds
    expect(described_class.send_code(email_address:, ip_address:)).to be_success
  end

  it "limits sends per email each hour" do
    5.times do
      expect(described_class.send_code(email_address:, ip_address:)).to be_success
      travel 61.seconds
    end

    expect(described_class.send_code(email_address:, ip_address:).error).to eq(:rate_limited)
  end

  it "limits sends per IP each hour" do
    5.times do |number|
      expect(described_class.send_code(email_address: "creator#{number}@example.com", ip_address:)).to be_success
    end

    expect(described_class.send_code(email_address: "another@example.com", ip_address:).error).to eq(:rate_limited)
  end

  it "invalidates a challenge after five failed attempts" do
    described_class.send_code(email_address:, ip_address:)

    5.times do
      expect(described_class.verify_code(email_address:, code: "000000", ip_address:)).not_to be_success
    end

    expect(described_class.verify_code(email_address:, code: "123456", ip_address:)).not_to be_success
  end

  it "invalidates the old code when a new code is sent" do
    described_class.send_code(email_address:, ip_address:)
    travel 61.seconds
    allow(SecureRandom).to receive(:random_number).and_return(654_321)
    described_class.send_code(email_address:, ip_address:)

    expect(described_class.verify_code(email_address:, code: "123456", ip_address:)).not_to be_success
    expect(described_class.verify_code(email_address:, code: "654321", ip_address:)).to be_success
  end

  it "accepts the configured local development code without a send step" do
    previous_code = Rails.application.config.x.authentication.development_otp_code
    Rails.application.config.x.authentication.development_otp_code = "424242"

    expect(described_class.verify_code(email_address:, code: "424242", ip_address:)).to be_success
    expect(described_class.verify_code(email_address:, code: "000000", ip_address:)).not_to be_success
    expect(described_class.send_code(email_address:, ip_address:)).to be_success
  ensure
    Rails.application.config.x.authentication.development_otp_code = previous_code
  end
end

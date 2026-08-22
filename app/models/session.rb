class Session < ApplicationRecord
  LIFETIME = 30.days
  ACTIVITY_UPDATE_INTERVAL = 1.hour

  Issued = Data.define(:session, :token)

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :last_active_at, :expires_at, presence: true

  scope :expired, -> { where(expires_at: ..Time.current) }

  class << self
    def issue_for(user:, user_agent:, ip_address:)
      raw_token = SecureRandom.urlsafe_base64(32)
      session = create!(
        user:,
        token_digest: digest(raw_token),
        user_agent: user_agent.to_s.first(1_000).presence,
        ip_address:,
        last_active_at: Time.current,
        expires_at: LIFETIME.from_now
      )

      Issued.new(session:, token: raw_token)
    end

    def find_by_token(raw_token)
      return if raw_token.blank?

      find_by(token_digest: digest(raw_token))
    end

    def prune_expired!
      expired.delete_all
    end

    private

    def digest(raw_token)
      Digest::SHA256.hexdigest(raw_token)
    end
  end

  def active?
    expires_at.future?
  end

  def record_activity!
    return if last_active_at > ACTIVITY_UPDATE_INTERVAL.ago

    update_column(:last_active_at, Time.current)
  end

  def revoke!
    destroy!
  end
end

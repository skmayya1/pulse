class OrganizationInvitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  enum :role, {
    admin: "admin",
    member: "member"
  }, validate: true

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil, expires_at: Time.current..) }
  scope :expired, -> { where(accepted_at: nil, revoked_at: nil, expires_at: ..Time.current) }
  scope :revoked, -> { where(accepted_at: nil).where.not(revoked_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }

  validates :email_address,
    presence: true,
    format: {with: URI::MailTo::EMAIL_REGEXP},
    uniqueness: {
      case_sensitive: false,
      scope: :organization_id,
      conditions: -> { where(accepted_at: nil, revoked_at: nil) }
    }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def self.find_by_token(raw_token)
    return if raw_token.blank?

    find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
  end
end

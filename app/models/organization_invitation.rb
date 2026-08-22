class OrganizationInvitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  enum :role, {
    admin: "admin",
    member: "member"
  }, validate: true

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
end

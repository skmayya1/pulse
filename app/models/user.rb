class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :organization_memberships, dependent: :restrict_with_error
  has_many :organizations, through: :organization_memberships
  has_many :organization_invitations, foreign_key: :invited_by_id, dependent: :restrict_with_error,
    inverse_of: :invited_by
  has_many :provider_connections, foreign_key: :connected_by_id, dependent: :restrict_with_error,
    inverse_of: :connected_by
  has_many :media, as: :uploadable, dependent: :restrict_with_error
  has_many :uploaded_media, class_name: "Media", foreign_key: :uploaded_by_id,
    inverse_of: :uploaded_by, dependent: :restrict_with_error
  has_many :created_posts, class_name: "Post", foreign_key: :created_by_id,
    inverse_of: :created_by, dependent: :restrict_with_error

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }
  normalizes :google_uid, with: ->(google_uid) { google_uid.strip.presence }

  validates :email_address,
    presence: true,
    format: {with: URI::MailTo::EMAIL_REGEXP},
    uniqueness: {case_sensitive: false}
  validates :name, length: {maximum: 100}, allow_blank: true
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :verified_at, presence: true
end

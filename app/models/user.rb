class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

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

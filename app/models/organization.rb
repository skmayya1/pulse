class Organization < ApplicationRecord
  TIME_ZONE_NAMES = ActiveSupport::TimeZone.all.map(&:name).freeze

  has_many :organization_memberships, dependent: :restrict_with_error
  has_many :members, through: :organization_memberships, source: :user
  has_many :organization_invitations, dependent: :restrict_with_error
  has_many :provider_connections, dependent: :restrict_with_error
  has_many :media, as: :uploadable, dependent: :restrict_with_error
  has_many :posts, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, length: {maximum: 100}
  validates :time_zone, presence: true, inclusion: {in: TIME_ZONE_NAMES}
end

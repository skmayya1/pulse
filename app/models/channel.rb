class Channel < ApplicationRecord
  PROVIDERS = %w[meta tiktok youtube].freeze

  has_many :provider_connections, dependent: :restrict_with_error

  enum :provider, PROVIDERS.index_with(&:itself), validate: true

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:position, :name, :id) }

  normalizes :key, with: ->(value) { value.to_s.strip.downcase }
  normalizes :name, :icon, with: ->(value) { value.to_s.strip }

  validates :key, presence: true, uniqueness: true, format: {with: /\A[a-z0-9_]+\z/}
  validates :name, :icon, presence: true
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}
end

class Channel < ApplicationRecord
  PROVIDERS = %w[instagram meta tiktok youtube].freeze
  CATALOG = [
    {key: "instagram", name: "Instagram", provider: "instagram", icon: "channels/instagram.png", position: 0},
    {key: "facebook", name: "Facebook", provider: "meta", icon: "channels/facebook.png", position: 1},
    {key: "tiktok", name: "TikTok", provider: "tiktok", icon: "channels/tiktok.png", position: 2},
    {key: "youtube", name: "YouTube", provider: "youtube", icon: "channels/youtube.png", position: 3}
  ].freeze

  has_many :provider_connections, dependent: :restrict_with_error

  enum :provider, PROVIDERS.index_with(&:itself), validate: true

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:position, :name, :id) }

  normalizes :key, with: ->(value) { value.to_s.strip.downcase }
  normalizes :name, :icon, with: ->(value) { value.to_s.strip }

  validates :key, presence: true, uniqueness: true, format: {with: /\A[a-z0-9_]+\z/}
  validates :name, :icon, presence: true
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  def self.upsert_catalog!
    CATALOG.each do |attributes|
      channel = find_or_initialize_by(key: attributes.fetch(:key))
      channel.assign_attributes(attributes)
      channel.save!
    end
  end
end

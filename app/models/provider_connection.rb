class ProviderConnection < ApplicationRecord
  STATUSES = %w[connected needs_reauthorization disconnected].freeze

  belongs_to :organization
  belongs_to :channel
  belongs_to :connected_by, class_name: "User", inverse_of: :provider_connections

  enum :status, STATUSES.index_with(&:itself), validate: true

  encrypts :access_token, :refresh_token

  normalizes :provider_account_id, :name, with: ->(value) { value.to_s.strip }
  normalizes :provider_identity_id, :handle, with: ->(value) { value.to_s.strip.presence }

  validates :provider_account_id, presence: true, uniqueness: {scope: :channel_id}
  validates :name, :access_token, :connected_at, presence: true

  def provider
    channel.provider
  end

  def serializable_hash(options = nil)
    super.except("access_token", "refresh_token")
  end
end

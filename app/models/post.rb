class Post < ApplicationRecord
  STATUSES = %w[draft scheduled published failed].freeze

  belongs_to :organization
  belongs_to :created_by, class_name: "User", inverse_of: :created_posts
  has_many :media_attachments, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :post
  has_many :media, through: :media_attachments

  enum :status, STATUSES.index_with(&:itself), default: :draft, validate: true

  normalizes :caption, with: ->(caption) { caption.to_s.strip.presence }

  validate :caption_or_media_present

  private

  def caption_or_media_present
    return if caption.present? || media_attachments.any?

    errors.add(:base, "Caption or media must be present")
  end
end

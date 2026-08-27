class Media < ApplicationRecord
  KINDS = %w[image video].freeze
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  VIDEO_CONTENT_TYPES = %w[video/mp4 video/quicktime video/webm].freeze
  IMAGE_MAX_BYTE_SIZE = 10.megabytes
  VIDEO_MAX_BYTE_SIZE = 100.megabytes
  MAX_BATCH = 5

  belongs_to :uploadable, polymorphic: true
  belongs_to :uploaded_by, class_name: "User", inverse_of: :uploaded_media
  has_many :media_attachments, dependent: :restrict_with_error
  has_many :posts, through: :media_attachments
  has_one_attached :file, dependent: :purge_later do |attachable|
    attachable.variant :thumb, resize_to_limit: [400, 400]
  end

  enum :kind, KINDS.index_with(&:itself), validate: true

  normalizes :filename, :content_type, with: ->(value) { value.to_s.strip }

  before_validation :copy_file_metadata, if: -> { file.attached? }

  validates :filename, :content_type, :byte_size, presence: true
  validates :byte_size, numericality: {only_integer: true, greater_than: 0}
  validates :width, :height, :duration_seconds,
    numericality: {only_integer: true, greater_than: 0},
    allow_nil: true
  validate :file_must_be_attached
  validate :file_must_match_kind

  private

  def copy_file_metadata
    self.filename = file.filename.to_s if filename.blank?
    self.content_type = file.content_type
    self.byte_size = file.byte_size
  end

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_must_match_kind
    return unless file.attached? && kind.present?

    types, max_size = if image?
      [IMAGE_CONTENT_TYPES, IMAGE_MAX_BYTE_SIZE]
    else
      [VIDEO_CONTENT_TYPES, VIDEO_MAX_BYTE_SIZE]
    end

    errors.add(:file, "is not an allowed type") unless types.include?(content_type)
    errors.add(:file, "is too large") if byte_size.present? && byte_size > max_size
  end
end

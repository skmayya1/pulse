class MediaAttachment < ApplicationRecord
  belongs_to :media
  belongs_to :post

  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :media_id, uniqueness: {scope: :post_id}
end

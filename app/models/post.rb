class Post < ApplicationRecord
  belongs_to :organization
  belongs_to :created_by, class_name: "User", inverse_of: :created_posts
  has_many :media_attachments, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :post
  has_many :media, through: :media_attachments
end

class AddStatusAndCaptionToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :status, :string, null: false, default: "draft"
    add_column :posts, :caption, :text
    add_check_constraint :posts,
      "status IN ('draft', 'scheduled', 'published', 'failed')",
      name: "posts_status_check",
      validate: false
  end
end

class AddIndexOnPostsOrganizationStatusAndCreated < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :posts, [:organization_id, :status, :created_at],
      order: {created_at: :desc},
      name: "index_posts_on_organization_status_and_created",
      algorithm: :concurrently
  end
end

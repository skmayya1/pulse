class CreateMediaAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :media_attachments do |t|
      t.references :media, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :media_attachments, [:post_id, :media_id], unique: true
    add_index :media_attachments, [:post_id, :position]
  end
end

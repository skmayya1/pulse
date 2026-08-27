class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.references :uploadable, polymorphic: true, null: false, index: false
      t.references :uploaded_by, null: false, foreign_key: {to_table: :users}
      t.string :kind, null: false
      t.string :filename, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.integer :width
      t.integer :height
      t.integer :duration_seconds
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :media, [:uploadable_type, :uploadable_id, :kind]
    add_check_constraint :media, "kind IN ('image', 'video')", name: "media_kind_check"
  end
end

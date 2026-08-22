class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :google_uid
      t.string :name
      t.datetime :verified_at, null: false

      t.timestamps
    end

    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email_address"
    add_index :users, :google_uid, unique: true
  end
end

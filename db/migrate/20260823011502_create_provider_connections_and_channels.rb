class CreateProviderConnectionsAndChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :channels do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.string :icon, null: false
      t.integer :position, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.jsonb :configuration, null: false, default: {}

      t.timestamps
    end

    add_index :channels, :key, unique: true
    add_index :channels, [:enabled, :position]

    create_table :provider_connections do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :channel, null: false, foreign_key: true
      t.references :connected_by, null: false, foreign_key: {to_table: :users}
      t.string :provider_account_id, null: false
      t.string :provider_identity_id
      t.string :name, null: false
      t.string :handle
      t.string :avatar_url
      t.text :access_token, null: false
      t.text :refresh_token
      t.datetime :token_expires_at
      t.string :scopes, array: true, null: false, default: []
      t.string :status, null: false, default: "connected"
      t.jsonb :metadata, null: false, default: {}
      t.datetime :connected_at, null: false
      t.datetime :last_synced_at
      t.datetime :disconnected_at

      t.timestamps
    end

    add_index :provider_connections,
      [:channel_id, :provider_account_id],
      unique: true,
      name: "index_provider_connections_on_channel_and_provider_account"
    add_index :provider_connections, [:organization_id, :channel_id, :status]
    add_index :provider_connections, [:status, :token_expires_at]
  end
end

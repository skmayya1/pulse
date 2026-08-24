# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_23_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "channels", force: :cascade do |t|
    t.jsonb "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "icon", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled", "position"], name: "index_channels_on_enabled_and_position"
    t.index ["key"], name: "index_channels_on_key", unique: true
  end

  create_table "organization_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "revoked_at"
    t.string "role", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index "organization_id, lower((email_address)::text)", name: "index_active_organization_invitations_on_email", unique: true, where: "((accepted_at IS NULL) AND (revoked_at IS NULL))"
    t.index ["expires_at"], name: "index_organization_invitations_on_expires_at"
    t.index ["invited_by_id"], name: "index_organization_invitations_on_invited_by_id"
    t.index ["organization_id"], name: "index_organization_invitations_on_organization_id"
    t.index ["token_digest"], name: "index_organization_invitations_on_token_digest", unique: true
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'member'::character varying]::text[])", name: "organization_invitations_role_check"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_and_user", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'admin'::character varying, 'member'::character varying]::text[])", name: "organization_memberships_role_check"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provider_connections", force: :cascade do |t|
    t.text "access_token"
    t.string "avatar_url"
    t.bigint "channel_id", null: false
    t.datetime "connected_at", null: false
    t.bigint "connected_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "disconnected_at"
    t.string "handle"
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "provider_account_id", null: false
    t.string "provider_identity_id"
    t.text "refresh_token"
    t.string "scopes", default: [], null: false, array: true
    t.string "status", default: "connected", null: false
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.index ["channel_id", "provider_account_id"], name: "index_provider_connections_on_channel_and_provider_account", unique: true
    t.index ["channel_id"], name: "index_provider_connections_on_channel_id"
    t.index ["connected_by_id"], name: "index_provider_connections_on_connected_by_id"
    t.index ["organization_id", "channel_id", "status"], name: "idx_on_organization_id_channel_id_status_e9334d1e9c"
    t.index ["organization_id"], name: "index_provider_connections_on_organization_id"
    t.index ["status", "token_expires_at"], name: "index_provider_connections_on_status_and_token_expires_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.inet "ip_address"
    t.datetime "last_active_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id", "expires_at"], name: "index_sessions_on_user_id_and_expires_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "google_uid"
    t.string "name"
    t.datetime "updated_at", null: false
    t.datetime "verified_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email_address", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "organization_invitations", "organizations"
  add_foreign_key "organization_invitations", "users", column: "invited_by_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "provider_connections", "channels"
  add_foreign_key "provider_connections", "organizations"
  add_foreign_key "provider_connections", "users", column: "connected_by_id"
  add_foreign_key "sessions", "users"
end

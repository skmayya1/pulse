class CreateOrganizationInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: {to_table: :users}
      t.string :email_address, null: false
      t.string :role, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :organization_invitations, :token_digest, unique: true
    add_index :organization_invitations, :expires_at
    add_index :organization_invitations,
      "organization_id, lower(email_address)",
      unique: true,
      where: "accepted_at IS NULL AND revoked_at IS NULL",
      name: "index_active_organization_invitations_on_email"
    add_check_constraint :organization_invitations,
      "role IN ('admin', 'member')",
      name: "organization_invitations_role_check"
  end
end

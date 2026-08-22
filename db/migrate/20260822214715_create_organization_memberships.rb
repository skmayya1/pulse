class CreateOrganizationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :organization_memberships,
      [:organization_id, :user_id],
      unique: true,
      name: "index_organization_memberships_on_organization_and_user"
    add_check_constraint :organization_memberships,
      "role IN ('owner', 'admin', 'member')",
      name: "organization_memberships_role_check"
  end
end

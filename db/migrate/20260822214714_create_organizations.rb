class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :time_zone, null: false, default: "UTC"

      t.timestamps
    end
  end
end

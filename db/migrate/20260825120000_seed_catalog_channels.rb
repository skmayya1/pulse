class SeedCatalogChannels < ActiveRecord::Migration[8.1]
  def up
    Channel.reset_column_information
    Channel.upsert_catalog!
  end

  def down
    Channel.where(key: Channel::CATALOG.map { |channel| channel.fetch(:key) }).find_each do |channel|
      channel.destroy!
    end
  end
end

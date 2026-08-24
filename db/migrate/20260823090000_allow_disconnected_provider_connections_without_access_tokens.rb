class AllowDisconnectedProviderConnectionsWithoutAccessTokens < ActiveRecord::Migration[8.1]
  def change
    change_column_null :provider_connections, :access_token, true
  end
end

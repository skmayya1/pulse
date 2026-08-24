module Settings
  module Organization
    class ProviderConnectionsController < ApplicationController
      def create
        channel = Channel.enabled.find_by!(key: params[:channel_key])
        authorize ProviderConnection.new(organization: current_organization, channel:, connected_by: current_user)

        result = ProviderConnections::StartAuthorizationService.call(
          user: current_user,
          organization: current_organization,
          channel:
        )
        return redirect_to result.authorization_url, allow_other_host: true if result.success?

        redirect_to settings_organization_channels_path, alert: failure_message(result.error)
      end

      def destroy
        connection = policy_scope(ProviderConnection).find(params[:id])
        authorize connection

        result = ProviderConnections::DisconnectService.call(connection:, user: current_user)
        redirect_to(
          settings_organization_channels_path(channel: connection.channel.key, anchor: "channel-#{connection.channel.key}"),
          result.success? ? {notice: "Account disconnected."} : {alert: "The account could not be disconnected."}
        )
      end

      private

      def failure_message(error)
        return "This provider has not been configured yet." if error == :unavailable

        "The connection could not be started."
      end
    end
  end
end

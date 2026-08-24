module Settings
  module Organization
    class OauthSelectionsController < ApplicationController
      def show
        prepare_page
        result = ProviderConnections::SelectionService.load(
          user: current_user,
          channel: @channel,
          token: params[:token]
        )
        return invalid_selection unless result.success?

        @candidates = result.candidates
        @selection_token = params[:token]
      end

      def create
        prepare_channel
        result = ProviderConnections::SelectionService.call(
          user: current_user,
          channel: @channel,
          token: selection_params[:token],
          selected_ids: selection_params[:account_ids]
        )
        return invalid_selection unless result.success?

        redirect_to settings_organization_channels_path(channel: @channel.key, anchor: "channel-#{@channel.key}"), notice: "Accounts connected."
      end

      private

      def prepare_page
        @page = SettingsController::PAGES.fetch(:organization_channels).merge(key: :organization_channels)
        prepare_channel
      end

      def prepare_channel
        @channel = Channel.enabled.find_by!(key: params[:channel_key])
        authorize ProviderConnection.new(organization: current_organization, channel: @channel, connected_by: current_user), :create?
      end

      def selection_params
        params.require(:oauth_selection).permit(:token, account_ids: [])
      end

      def invalid_selection
        redirect_to settings_organization_channels_path, alert: "The account selection expired or could not be completed."
      end
    end
  end
end

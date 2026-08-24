class ProviderConnectionOauthController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    return redirect_to login_path, alert: "Sign in again before connecting an account." if current_user.blank?

    result = ProviderConnections::CompleteAuthorizationService.call(
      user: current_user,
      provider: params[:provider],
      state: params[:state],
      code: params[:code],
      provider_error: params[:error]
    )
    return oauth_failure(result.error) unless result.success?

    if result.selection_required?
      redirect_to settings_organization_channel_oauth_selection_path(
        result.channel.key,
        token: result.selection_token
      )
    else
      redirect_to settings_organization_channels_path(channel: result.channel.key, anchor: "channel-#{result.channel.key}"), notice: "Account connected."
    end
  end

  private

  def oauth_failure(error)
    message = case error
    when :no_accounts
      "No eligible accounts were found."
    when :temporary
      "The provider is temporarily unavailable. Try again."
    when :already_connected
      "That account is already connected to a workspace."
    else
      "The connection could not be completed."
    end

    redirect_to settings_organization_channels_path, alert: message
  end
end

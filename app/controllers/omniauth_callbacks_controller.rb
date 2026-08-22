class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access

  def create
    authentication = request.env.fetch("omniauth.auth")
    return reject_google_authentication unless verified_google_email?(authentication)

    result = Authentication::ResolveUserService.call(
      provider: authentication.provider,
      uid: authentication.uid,
      email_address: authentication.info.email,
      name: authentication.info.name
    )
    return reject_google_authentication unless result.success?

    start_new_session_for(result.user)
    redirect_to post_authentication_url
  rescue KeyError
    reject_google_authentication
  end

  def failure
    reject_google_authentication
  end

  private

  def verified_google_email?(authentication)
    authentication.provider == "google_oauth2" &&
      authentication.info.email.present? &&
      ActiveModel::Type::Boolean.new.cast(authentication.dig("extra", "raw_info", "email_verified"))
  end

  def reject_google_authentication
    redirect_to login_path, alert: "Google sign-in could not be completed."
  end
end

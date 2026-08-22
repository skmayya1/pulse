class AuthenticationController < ApplicationController
  allow_unauthenticated_access only: [:new, :create, :google_callback, :failure]
  allow_organizationless_access

  def new
    return redirect_to post_authentication_url if current_user.present?

    render "sessions/new"
  end

  def create
    @email_address = authentication_params[:email_address].to_s.strip.downcase
    return request_email_code if authentication_params[:code].blank?

    verify_email_code
  end

  def destroy
    terminate_current_session
    redirect_to login_path, status: :see_other
  end

  def google_callback
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

  def request_email_code
    Authentication::OtpService.send_code(email_address: @email_address, ip_address: request.remote_ip)

    flash[:email_address] = @email_address
    redirect_to login_path, status: :see_other
  end

  def verify_email_code
    result = Authentication::OtpService.verify_code(
      email_address: @email_address,
      code: authentication_params[:code],
      ip_address: request.remote_ip
    )

    unless result.success?
      flash.now[:alert] = "The code could not be verified. Request a new code and try again."
      return render "sessions/new", status: :unprocessable_content
    end

    resolved_user = Authentication::ResolveUserService.call(
      provider: "email",
      uid: @email_address,
      email_address: @email_address,
      name: nil
    )

    unless resolved_user.success?
      flash.now[:alert] = "The code could not be verified. Request a new code and try again."
      return render "sessions/new", status: :unprocessable_content
    end

    start_new_session_for(resolved_user.user)
    redirect_to post_authentication_url
  end

  def verified_google_email?(authentication)
    authentication.provider == "google_oauth2" &&
      authentication.info.email.present? &&
      ActiveModel::Type::Boolean.new.cast(authentication.dig("extra", "raw_info", "email_verified"))
  end

  def reject_google_authentication
    redirect_to login_path, alert: "Google sign-in could not be completed."
  end

  def authentication_params
    params.require(:authentication).permit(:email_address, :code)
  end
end

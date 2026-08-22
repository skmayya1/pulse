class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]

  def new
    redirect_to post_authentication_url if signed_in?
  end

  def create
    @email_address = authentication_params[:email_address].to_s.strip.downcase
    result = Authentication::OtpService.verify_code(
      email_address: @email_address,
      code: authentication_params[:code],
      ip_address: request.remote_ip
    )

    unless result.success?
      flash.now[:alert] = "The code could not be verified. Request a new code and try again."
      return render :new, status: :unprocessable_content
    end

    resolved_user = Authentication::ResolveUserService.call(
      provider: "email",
      uid: @email_address,
      email_address: @email_address,
      name: nil
    )

    unless resolved_user.success?
      flash.now[:alert] = "The code could not be verified. Request a new code and try again."
      return render :new, status: :unprocessable_content
    end

    start_new_session_for(resolved_user.user)
    redirect_to post_authentication_url
  end

  def destroy
    terminate_current_session
    redirect_to login_path, status: :see_other
  end

  private

  def authentication_params
    params.require(:authentication).permit(:email_address, :code)
  end
end

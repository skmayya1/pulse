module Authentication
  class EmailCodesController < ApplicationController
    allow_unauthenticated_access

    def create
      email_address = authentication_params[:email_address].to_s.strip.downcase
      OtpService.send_code(email_address:, ip_address: request.remote_ip)

      flash[:email_address] = email_address
      redirect_to login_path, status: :see_other
    end

    private

    def authentication_params
      params.require(:authentication).permit(:email_address)
    end
  end
end

module Authentication
  extend ActiveSupport::Concern

  SESSION_COOKIE = :pulse_session

  included do
    before_action :restore_authentication
    before_action :require_authentication

    helper_method :current_session, :current_user, :signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  def require_authentication
    return if signed_in?

    session[:return_to_after_authenticating] = request.fullpath if request.get? || request.head?
    redirect_to login_path
  end

  def restore_authentication
    Current.clear
    authenticated_session = Session.find_by_token(cookies.signed[SESSION_COOKIE])
    return unless authenticated_session

    unless authenticated_session.active?
      authenticated_session.revoke!
      clear_session_cookie
      return
    end

    Current.establish!(authenticated_session)
    authenticated_session.record_activity!
  rescue ActiveRecord::RecordNotFound
    authenticated_session&.revoke!
    clear_session_cookie
    Current.clear
  end

  def start_new_session_for(user)
    @return_to_after_authenticating = session.delete(:return_to_after_authenticating)
    reset_session

    issued = Session.issue_for(
      user:,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    cookies.signed[SESSION_COOKIE] = session_cookie_options(
      value: issued.token,
      expires: issued.session.expires_at
    )
    Current.establish!(issued.session)
    issued.session
  end

  def terminate_current_session
    current_session&.revoke!
    clear_session_cookie
    reset_session
    Current.clear
  end

  def post_authentication_url
    @return_to_after_authenticating.presence || root_path
  end

  def current_session = Current.session
  def current_user = Current.user
  def signed_in? = current_user.present?

  private

  def clear_session_cookie
    cookies.delete(SESSION_COOKIE, **session_cookie_clear_options)
  end

  def session_cookie_options(value:, expires:)
    session_cookie_clear_options.merge(value:, expires:, httponly: true)
  end

  def session_cookie_clear_options
    {secure: Rails.env.production?, same_site: :lax}
  end
end

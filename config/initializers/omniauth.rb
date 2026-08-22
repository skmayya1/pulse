google_client_id = ENV["GOOGLE_CLIENT_ID"].presence
google_client_secret = ENV["GOOGLE_CLIENT_SECRET"].presence
google_oauth_enabled = google_client_id.present? && google_client_secret.present?

Rails.application.config.x.authentication.google_oauth_enabled = google_oauth_enabled

if google_oauth_enabled
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
      google_client_id,
      google_client_secret,
      scope: "email,profile",
      access_type: "online",
      prompt: "select_account"
  end
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.full_host = ENV["APP_HOST"] if ENV["APP_HOST"].present?

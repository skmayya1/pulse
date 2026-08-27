Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/dev/mail" if Rails.env.development?

  get "/auth/login", to: "authentication#new", as: :login
  post "/auth/login", to: "authentication#create"
  delete "/auth/logout", to: "authentication#destroy", as: :logout

  get "/auth/:provider/callback", to: "authentication#google_callback"
  get "/auth/failure", to: "authentication#failure"

  resources :organization_invitations, only: :show, param: :token
  resources :organizations, only: [:new, :create]

  get "/settings", to: "settings#show", as: :settings
  get "/settings/profile", to: "settings#profile", as: :settings_profile
  patch "/settings/profile", to: "settings#update_profile"
  get "/settings/preferences", to: "settings#preferences", as: :settings_preferences
  get "/settings/notifications", to: "settings#notifications", as: :settings_notifications
  get "/settings/organization/general", to: "settings#organization_general", as: :settings_organization_general
  patch "/settings/organization/general", to: "settings#update_organization"
  get "/settings/organization/channels", to: "settings#organization_channels", as: :settings_organization_channels
  get "/settings/organization/members", to: "settings#organization_members", as: :settings_organization_members
  post "/settings/organization/invitations", to: "settings/organization/invitations#create", as: :settings_organization_invitations

  namespace :settings do
    namespace :organization do
      resources :channels, only: [], param: :key do
        resources :provider_connections, only: :create
        resource :oauth_selection, only: [:show, :create]
      end

      resources :provider_connections, only: :destroy
    end
  end

  get "/oauth/provider-connections/:provider/callback",
    to: "provider_connection_oauth#show",
    as: :provider_connection_oauth_callback

  resources :media, only: [:index, :create, :destroy]

  root "home#index"
end

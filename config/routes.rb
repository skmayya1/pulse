Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  get "/auth/login", to: "authentication#new", as: :login
  post "/auth/login", to: "authentication#create"
  delete "/auth/logout", to: "authentication#destroy", as: :logout

  get "/auth/:provider/callback", to: "authentication#google_callback"
  get "/auth/failure", to: "authentication#failure"

  resources :organization_invitations, only: :show, param: :token
  resources :organizations, only: [:new, :create]

  get "/settings", to: "settings#show", as: :settings
  get "/settings/profile", to: "settings#profile", as: :settings_profile
  get "/settings/preferences", to: "settings#preferences", as: :settings_preferences
  get "/settings/notifications", to: "settings#notifications", as: :settings_notifications
  get "/settings/organization/general", to: "settings#organization_general", as: :settings_organization_general
  get "/settings/organization/channels", to: "settings#organization_channels", as: :settings_organization_channels
  get "/settings/organization/members", to: "settings#organization_members", as: :settings_organization_members
  post "/settings/organization/invitations", to: "settings/organization/invitations#create", as: :settings_organization_invitations

  root "home#index"
end

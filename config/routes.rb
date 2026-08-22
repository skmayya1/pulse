Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  get "/auth/login", to: "authentication#new", as: :login
  post "/auth/login", to: "authentication#create"
  delete "/auth/logout", to: "authentication#destroy", as: :logout

  get "/auth/:provider/callback", to: "authentication#google_callback"
  get "/auth/failure", to: "authentication#failure"

  resources :organization_invitations, only: :show, param: :token
  resources :organizations, only: [:new, :create]

  root "home#index"
end

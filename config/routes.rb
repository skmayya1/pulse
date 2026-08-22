Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  get "/auth/login", to: "sessions#new", as: :login
  resource :session, only: [:create, :destroy]
  namespace :authentication do
    resource :email_code, only: :create
  end

  get "/auth/:provider/callback", to: "omniauth_callbacks#create"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  root "home#index"
end

Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  resource :profile, only: [:edit, :update]
  get "/u/:username", to: "profiles#show", as: :user_profile

  get "up" => "rails/health#show", as: :rails_health_check
end
# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  root 'home#index'
  get '/feed', to: 'feed#index', as: :feed

  resource :profile, only: %i[edit update]
  get '/u/:username', to: 'profiles#show', as: :user_profile
  post '/u/:username/follow', to: 'follows#create', as: :follow_user
  delete '/u/:username/follow', to: 'follows#destroy', as: :unfollow_user

  resources :weekly_digests, only: %i[index show new create edit update] do
    member do
      patch :publish
      patch :unpublish
      post :generate
    end
  end

  resources :entries, only: %i[index new create destroy]

  resources :prompt_dispatches, only: [] do
    member do
      patch :skip
    end
  end

  # Twilio inbound webhook
  post '/webhooks/twilio', to: 'twilio_webhooks#inbound'

  # Phone verification
  resource :phone_verification, only: %i[new create] do
    get  :verify
    post :confirm
  end
end
# rubocop:enable Metrics/BlockLength

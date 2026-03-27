# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  root 'home#index'

  resource :profile, only: %i[edit update]
  get '/u/:username', to: 'profiles#show', as: :user_profile
  post '/u/:username/follow', to: 'follows#create', as: :follow_user
  delete '/u/:username/follow', to: 'follows#destroy', as: :unfollow_user

  resources :weekly_digests, only: %i[index show new create edit update] do
    member do
      patch :publish
      patch :unpublish
    end
  end

  resources :entries, only: %i[index new create destroy]

  resources :prompt_dispatches, only: [] do
    member do
      patch :skip
    end
  end
end

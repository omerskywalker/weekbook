# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  root 'home#index'

  resource :profile, only: %i[edit update]
  get '/u/:username', to: 'profiles#show', as: :user_profile
  post '/u/:username/follow', to: 'follows#create', as: :follow_user
  delete '/u/:username/follow', to: 'follows#destroy', as: :unfollow_user
end

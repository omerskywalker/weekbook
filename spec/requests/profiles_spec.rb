# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  describe 'GET /u/:username' do
    it 'returns success for an existing profile' do
      user = create(:user, username: 'omer')

      get user_profile_path(user.username)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('omer')
    end
  end

  describe 'GET /profile/edit' do
    it 'redirects unauthenticated users' do
      get edit_profile_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns success for authenticated users' do
      user = create(:user)
      sign_in user

      get edit_profile_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /profile' do
    it 'updates the current user profile' do
      user = create(:user, username: nil, display_name: nil, bio: nil)
      sign_in user

      patch profile_path, params: {
        user: {
          username: 'omer_123',
          display_name: 'Omer Siddiqui',
          bio: 'Building Weekbook in Rails.'
        }
      }

      expect(response).to redirect_to(user_profile_path('omer_123'))
      expect(user.reload.username).to eq('omer_123')
      expect(user.display_name).to eq('Omer Siddiqui')
      expect(user.bio).to eq('Building Weekbook in Rails.')
    end

    it 'renders unprocessable_entity for invalid input' do
      user = create(:user)
      sign_in user

      patch profile_path, params: {
        user: {
          username: 'not valid!'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

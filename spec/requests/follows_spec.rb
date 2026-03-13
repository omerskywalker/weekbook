# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Follows', type: :request do
  describe 'POST /u/:username/follow' do
    it 'redirects unauthenticated users' do
      user = create(:user, username: 'omer')

      post follow_user_path(user.username)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'allows an authenticated user to follow another user' do
      follower = create(:user)
      followed = create(:user, username: 'omer')
      sign_in follower

      post follow_user_path(followed.username)

      expect(response).to redirect_to(user_profile_path(followed.username))
      expect(follower.following?(followed)).to be(true)
    end

    it 'does not allow a user to follow themselves' do
      user = create(:user, username: 'omer')
      sign_in user

      post follow_user_path(user.username)

      expect(response).to redirect_to(user_profile_path(user.username))
      expect(user.following?(user)).to be(false)
    end
  end

  describe 'DELETE /u/:username/follow' do
    it 'allows an authenticated user to unfollow another user' do
      follower = create(:user)
      followed = create(:user, username: 'omer')
      create(:follow, follower:, followed:)
      sign_in follower

      delete follow_user_path(followed.username)

      expect(response).to redirect_to(user_profile_path(followed.username))
      expect(follower.reload.following?(followed)).to be(false)
    end
  end
end
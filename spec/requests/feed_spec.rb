# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Feed', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /feed' do
    context 'when signed out' do
      it 'redirects to sign in' do
        get feed_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns 200' do
        get feed_path
        expect(response).to have_http_status(:ok)
      end

      context 'when following a user with published digests' do
        before do
          Follow.create!(follower: user, followed: other_user)
          create(:weekly_digest, user: other_user, status: 'published',
                                 week_start_date: Date.current.beginning_of_week(:monday),
                                 week_number: Date.current.cweek, year: Date.current.cwyear)
        end

        it 'shows the digest in the feed' do
          get feed_path
          expect(response.body).to include(other_user.name_for_display)
        end
      end

      context 'when not following anyone' do
        it 'shows the empty feed state' do
          get feed_path
          expect(response.body).to include('Your feed is empty')
        end

        it 'shows people to follow when active publishers exist' do
          create(:weekly_digest, user: other_user, status: 'published',
                                 week_start_date: Date.current.beginning_of_week(:monday),
                                 week_number: Date.current.cweek, year: Date.current.cwyear)
          get feed_path
          expect(response.body).to include('People to follow')
        end
      end

      context 'when following a user with only draft digests' do
        before do
          Follow.create!(follower: user, followed: other_user)
          create(:weekly_digest, user: other_user, status: 'draft',
                                 week_start_date: Date.current.beginning_of_week(:monday),
                                 week_number: Date.current.cweek, year: Date.current.cwyear)
        end

        it 'does not show draft digests' do
          get feed_path
          expect(response.body).not_to include(other_user.name_for_display)
        end
      end
    end
  end
end

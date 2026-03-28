# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WeeklyDigests', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /weekly_digests' do
    it 'redirects unauthenticated users' do
      get weekly_digests_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns success for authenticated users' do
      sign_in user
      get weekly_digests_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /weekly_digests/:id' do
    context 'with a published digest' do
      let(:digest) { create(:weekly_digest, :published, user: user) }

      it 'is publicly accessible' do
        get weekly_digest_path(digest)
        expect(response).to have_http_status(:success)
      end
    end

    context 'with a draft digest' do
      let(:digest) { create(:weekly_digest, user: user) }

      it 'is accessible by the owner' do
        sign_in user
        get weekly_digest_path(digest)
        expect(response).to have_http_status(:success)
      end

      it 'redirects other users' do
        sign_in other_user
        get weekly_digest_path(digest)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /weekly_digests/new' do
    it 'redirects unauthenticated users' do
      get new_weekly_digest_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns success for authenticated users' do
      sign_in user
      get new_weekly_digest_path
      expect(response).to have_http_status(:success)
    end

    it 'redirects to edit if digest for this week exists' do
      digest = create(:weekly_digest, user: user)
      sign_in user
      get new_weekly_digest_path
      expect(response).to redirect_to(edit_weekly_digest_path(digest))
    end
  end

  describe 'POST /weekly_digests' do
    it 'creates a digest for authenticated users' do
      sign_in user
      expect do
        post weekly_digests_path, params: {
          weekly_digest: { content: 'A great week.', summary_line: 'Summary' }
        }
      end.to change(WeeklyDigest, :count).by(1)
    end

    it 'redirects to edit after creation' do
      sign_in user
      post weekly_digests_path, params: {
        weekly_digest: { content: 'A great week.', summary_line: 'Summary' }
      }
      expect(response).to redirect_to(edit_weekly_digest_path(WeeklyDigest.last))
    end
  end

  describe 'PATCH /weekly_digests/:id/publish' do
    let(:digest) { create(:weekly_digest, user: user) }

    it 'publishes the digest for the owner' do
      sign_in user
      patch publish_weekly_digest_path(digest)
      expect(digest.reload.status).to eq('published')
    end

    it 'enqueues NotifyFollowersJob on publish' do
      ActiveJob::Base.queue_adapter = :test
      sign_in user
      expect do
        patch publish_weekly_digest_path(digest)
      end.to have_enqueued_job(NotifyFollowersJob).with(digest.id)
    ensure
      ActiveJob::Base.queue_adapter = :sidekiq
    end

    it 'rejects non-owners' do
      sign_in other_user
      patch publish_weekly_digest_path(digest)
      expect(response).to redirect_to(root_path)
      expect(digest.reload.status).to eq('draft')
    end
  end

  describe 'PATCH /weekly_digests/:id/unpublish' do
    let(:digest) { create(:weekly_digest, :published, user: user) }

    it 'unpublishes the digest for the owner' do
      sign_in user
      patch unpublish_weekly_digest_path(digest)
      expect(digest.reload.status).to eq('draft')
    end
  end
end

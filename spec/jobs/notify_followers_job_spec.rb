# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifyFollowersJob, type: :job do
  let(:author) { create(:user) }
  let(:follower) { create(:user) }
  let(:digest) { create(:weekly_digest, user: author, status: 'published') }

  before { follower.active_follows.create!(followed: author) }

  describe '#perform' do
    it 'sends an email to each follower' do
      expect do
        described_class.new.perform(digest.id)
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'does nothing for a non-existent digest' do
      expect do
        described_class.new.perform(999_999)
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end

    it 'does nothing if digest is not published' do
      draft = create(:weekly_digest, user: author, status: 'draft')
      expect do
        described_class.new.perform(draft.id)
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end
end

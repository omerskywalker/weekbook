# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeeklyDigestAutoGenerateJob, type: :job do
  let(:week_start) { Date.current.beginning_of_week(:monday) }

  describe '#perform' do
    context 'when a user has no entries this week' do
      let!(:user) { create(:user) }

      it 'does not enqueue DigestSummarizerJob for that user' do
        expect { described_class.new.perform }
          .not_to have_enqueued_job(DigestSummarizerJob)
      end
    end

    context 'when a user has entries this week' do
      let!(:user)  { create(:user) }
      let!(:entry) { create(:entry, user: user, week_start_date: week_start) }

      it 'enqueues DigestSummarizerJob for that user' do
        expect { described_class.new.perform }
          .to have_enqueued_job(DigestSummarizerJob).with(user.id, anything)
      end

      it 'creates a draft digest if one does not exist yet' do
        expect { described_class.new.perform }
          .to change(WeeklyDigest, :count).by(1)
      end
    end

    context 'when the digest is already published' do
      let!(:user)   { create(:user) }
      let!(:entry)  { create(:entry, user: user, week_start_date: week_start) }
      let!(:digest) { create(:weekly_digest, :published, user: user, week_start_date: week_start) }

      it 'skips that digest and does not enqueue DigestSummarizerJob' do
        expect { described_class.new.perform }
          .not_to have_enqueued_job(DigestSummarizerJob)
      end
    end

    context 'when the digest is already archived' do
      let!(:user)   { create(:user) }
      let!(:entry)  { create(:entry, user: user, week_start_date: week_start) }
      let!(:digest) { create(:weekly_digest, :archived, user: user, week_start_date: week_start) }

      it 'skips that digest and does not enqueue DigestSummarizerJob' do
        expect { described_class.new.perform }
          .not_to have_enqueued_job(DigestSummarizerJob)
      end
    end
  end
end

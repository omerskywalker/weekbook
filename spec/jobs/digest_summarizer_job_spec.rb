# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigestSummarizerJob, type: :job do
  let(:user) { create(:user) }
  let(:week_start) { Date.current.beginning_of_week(:monday) }

  describe '#perform' do
    context 'when user is not found' do
      it 'returns early without raising' do
        expect { described_class.new.perform(-1, week_start.to_s) }.not_to raise_error
      end

      it 'does not create a digest' do
        expect do
          described_class.new.perform(-1, week_start.to_s)
        end.not_to change(WeeklyDigest, :count)
      end
    end

    context 'when user has no entries this week' do
      it 'returns early without creating a digest' do
        expect do
          described_class.new.perform(user.id, week_start.to_s)
        end.not_to change(WeeklyDigest, :count)
      end
    end

    context 'when user has entries this week' do
      let!(:entry) { create(:entry, user: user, week_start_date: week_start) }

      context 'when OpenaiSummarizer returns a narrative' do
        let(:narrative) { 'It was a genuinely good week. The work felt meaningful and real.' }

        before do
          allow_any_instance_of(OpenaiSummarizer).to receive(:call).and_return(narrative)
        end

        it 'creates or updates the digest with the narrative' do
          described_class.new.perform(user.id, week_start.to_s)
          digest = WeeklyDigest.find_by(user: user, week_start_date: week_start)
          expect(digest).to be_present
          expect(digest.content).to eq(narrative)
        end

        it 'sets summary_line to the first sentence truncated to 160 chars' do
          described_class.new.perform(user.id, week_start.to_s)
          digest = WeeklyDigest.find_by(user: user, week_start_date: week_start)
          expect(digest.summary_line).to eq('It was a genuinely good week')
        end
      end

      context 'when OpenaiSummarizer returns nil' do
        before do
          allow_any_instance_of(OpenaiSummarizer).to receive(:call).and_return(nil)
        end

        it 'does not create a digest' do
          expect do
            described_class.new.perform(user.id, week_start.to_s)
          end.not_to change(WeeklyDigest, :count)
        end
      end
    end
  end
end

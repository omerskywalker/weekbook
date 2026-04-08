# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigestSummarizerJob, type: :job do
  let(:user)       { create(:user) }
  let(:week_start) { Date.current.beginning_of_week(:monday) }
  let!(:digest)    { create(:weekly_digest, user: user, week_start_date: week_start) }

  describe '#perform' do
    context 'when user is not found' do
      it 'returns early without raising' do
        expect { described_class.new.perform(-1, digest.id) }.not_to raise_error
      end

      it 'does not update a digest' do
        expect do
          described_class.new.perform(-1, digest.id)
        end.not_to(change { digest.reload.content })
      end
    end

    context 'when digest is not found' do
      it 'returns early without raising' do
        expect { described_class.new.perform(user.id, -1) }.not_to raise_error
      end
    end

    context 'when user has no entries this week' do
      it 'returns early without updating the digest' do
        expect do
          described_class.new.perform(user.id, digest.id)
        end.not_to(change { digest.reload.content })
      end
    end

    context 'when user has entries this week' do
      let!(:entry) { create(:entry, user: user, week_start_date: week_start) }

      context 'when OpenaiSummarizer returns a narrative' do
        let(:narrative) { 'It was a genuinely good week. The work felt meaningful and real.' }

        before do
          allow_any_instance_of(OpenaiSummarizer).to receive(:call).and_return(narrative)
        end

        it 'updates the digest with the narrative' do
          described_class.new.perform(user.id, digest.id)
          expect(digest.reload.content).to eq(narrative)
        end

        it 'sets summary_line to the first sentence truncated to 160 chars' do
          described_class.new.perform(user.id, digest.id)
          expect(digest.reload.summary_line).to eq('It was a genuinely good week')
        end
      end

      context 'when OpenaiSummarizer returns nil' do
        before do
          allow_any_instance_of(OpenaiSummarizer).to receive(:call).and_return(nil)
        end

        it 'does not update the digest content' do
          expect do
            described_class.new.perform(user.id, digest.id)
          end.not_to(change { digest.reload.content })
        end
      end
    end

    context 'LLM prompt formatting' do
      let(:narrative) { 'A fine week.' }

      before do
        allow_any_instance_of(OpenaiSummarizer).to receive(:call).and_return(narrative)
      end

      context 'when entry has a prompt_text' do
        let!(:entry) do
          create(:entry, user: user, week_start_date: week_start,
                         prompt_text: 'What challenged you most this week?')
        end

        it 'passes entries with prompt_text to the summarizer' do
          captured_entries = nil
          allow(OpenaiSummarizer).to receive(:new) do |entries, **_kwargs|
            captured_entries = entries
            instance_double(OpenaiSummarizer, call: narrative)
          end

          described_class.new.perform(user.id, digest.id)
          expect(captured_entries.first.prompt_text).to eq('What challenged you most this week?')
        end
      end

      context 'when entry has no prompt_text' do
        let!(:entry) { create(:entry, user: user, week_start_date: week_start, prompt_text: nil) }

        it 'passes entries with nil prompt_text to the summarizer' do
          captured_entries = nil
          allow(OpenaiSummarizer).to receive(:new) do |entries, **_kwargs|
            captured_entries = entries
            instance_double(OpenaiSummarizer, call: narrative)
          end

          described_class.new.perform(user.id, digest.id)
          expect(captured_entries.first.prompt_text).to be_nil
        end
      end
    end
  end
end

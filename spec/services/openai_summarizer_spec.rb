# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenaiSummarizer do
  describe '#call' do
    context 'when entries are empty' do
      it 'returns nil' do
        summarizer = described_class.new([])
        expect(summarizer.call).to be_nil
      end
    end

    context 'when OPENAI_API_KEY is not set' do
      let(:user) { create(:user) }
      let(:entry) { create(:entry, user: user) }

      it 'returns nil' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
        allow(ENV).to receive(:fetch).and_call_original
        summarizer = described_class.new([entry])
        expect(summarizer.call).to be_nil
      end

      it 'returns nil when key is blank string' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("   ")
        allow(ENV).to receive(:fetch).and_call_original
        summarizer = described_class.new([entry])
        expect(summarizer.call).to be_nil
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmsService do
  describe '.configured?' do
    it 'returns false when env vars are absent' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TELNYX_API_KEY').and_return(nil)
      expect(described_class.configured?).to be false
    end
  end

  describe '.send_sms!' do
    it 'returns nil without making API call when not configured' do
      allow(described_class).to receive(:configured?).and_return(false)
      expect(described_class.send_sms!(to: '+15551234567', body: 'test')).to be_nil
    end
  end
end

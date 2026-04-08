# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmsPromptJob do
  describe '#perform' do
    it 'does nothing when SMS is not configured' do
      allow(SmsService).to receive(:configured?).and_return(false)
      expect(SmsService).not_to receive(:send_sms!)
      described_class.new.perform
    end

    it 'sends SMS to verified users when configured' do
      allow(SmsService).to receive(:configured?).and_return(true)
      user = create(:user, phone: '+15551234567', phone_verified: true)
      template = create(:prompt_template)
      create(:prompt_dispatch, user: user, prompt_template: template,
                               week_start_date: Date.current.beginning_of_week(:monday))
      expect(SmsService).to receive(:send_sms!).with(
        to: '+15551234567',
        body: a_string_including(template.body)
      )
      described_class.new.perform
    end
  end
end

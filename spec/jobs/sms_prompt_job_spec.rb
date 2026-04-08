# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmsPromptJob do
  describe '#perform' do
    it 'does nothing when SMS is not configured' do
      allow(SmsService).to receive(:configured?).and_return(false)
      expect(SmsService).not_to receive(:send_sms!)
      described_class.new.perform
    end

    it 'skips user who already received a prompt today' do
      allow(SmsService).to receive(:configured?).and_return(true)
      user = create(:user, phone: '+15551234567', phone_verified: true)
      template = create(:prompt_template)
      create(:prompt_dispatch, user: user, prompt_template: template, date: Date.current)
      expect(SmsService).not_to receive(:send_sms!)
      described_class.new.perform
    end

    it 'sends SMS and creates dispatch for verified users with no prompt today' do
      allow(SmsService).to receive(:configured?).and_return(true)
      create(:user, phone: '+15551234567', phone_verified: true)
      template = create(:prompt_template)
      allow(PromptTemplate).to receive(:random_for_week).and_return(template)
      expect(SmsService).to receive(:send_sms!).with(
        to: '+15551234567',
        body: a_string_including(template.body)
      )
      described_class.new.perform
    end

    it 'includes reply instructions in the message body' do
      allow(SmsService).to receive(:configured?).and_return(true)
      create(:user, phone: '+15551234567', phone_verified: true)
      template = create(:prompt_template)
      allow(PromptTemplate).to receive(:random_for_week).and_return(template)
      expect(SmsService).to receive(:send_sms!).with(
        to: '+15551234567',
        body: a_string_including('Reply to save it to your Weekbook')
      )
      described_class.new.perform
    end

    it 'does not send SMS to users with unverified phones' do
      allow(SmsService).to receive(:configured?).and_return(true)
      create(:user, phone: '+15559999999', phone_verified: false)
      expect(SmsService).not_to receive(:send_sms!)
      described_class.new.perform
    end
  end
end

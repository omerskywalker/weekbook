# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::Sms' do
  describe 'POST /webhooks/sms' do
    def telnyx_payload(from:, text:)
      {
        data: {
          event_type: 'message.received',
          payload: {
            from: { phone_number: from },
            text: text
          }
        }
      }.to_json
    end

    def post_sms(from:, text:)
      post '/webhooks/sms',
           params: telnyx_payload(from: from, text: text),
           headers: { 'Content-Type' => 'application/json' }
    end

    context 'when TELNYX_PUBLIC_KEY is not set (signature check skipped)' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('TELNYX_PUBLIC_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).and_call_original
      end

      context 'when number is not linked to a verified account' do
        it 'returns 200 and does not create an entry' do
          expect do
            post_sms(from: '+15559999999', text: 'Hello there')
          end.not_to change(Entry, :count)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when number belongs to a verified user' do
        let!(:user) { create(:user, phone: '+15551234567', phone_verified: true) }

        it 'creates an entry and returns 200' do
          expect do
            post_sms(from: '+15551234567', text: 'Had a great day today in the office')
          end.to change(user.entries, :count).by(1)
          expect(response).to have_http_status(:ok)
        end

        it 'sets week_start_date to the current Monday' do
          post_sms(from: '+15551234567', text: 'Had a great day today in the office')
          expect(user.entries.last.week_start_date).to eq(Date.current.beginning_of_week(:monday))
        end

        it 'does not create an entry when text is too short' do
          post_sms(from: '+15551234567', text: 'Hi')
          expect(user.entries.count).to eq(0)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when text is SKIP (case-insensitive)' do
        let!(:user) { create(:user, phone: '+15551234567', phone_verified: true) }
        let!(:template) { create(:prompt_template) }
        let!(:dispatch) do
          create(:prompt_dispatch,
                 user: user,
                 prompt_template: template,
                 week_start_date: Date.current.beginning_of_week(:monday))
        end

        it 'skips the current week dispatch' do
          post_sms(from: '+15551234567', text: 'SKIP')
          expect(dispatch.reload.status).to eq('skipped')
        end

        it 'also skips when text is lowercase skip' do
          post_sms(from: '+15551234567', text: 'skip')
          expect(dispatch.reload.status).to eq('skipped')
        end

        it 'does not create an entry' do
          expect do
            post_sms(from: '+15551234567', text: 'SKIP')
          end.not_to change(Entry, :count)
        end

        it 'returns 200' do
          post_sms(from: '+15551234567', text: 'SKIP')
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when phone is not verified' do
        let!(:user) { create(:user, phone: '+15552223333', phone_verified: false) }

        it 'does not create an entry' do
          expect do
            post_sms(from: '+15552223333', text: 'Test entry from unverified number')
          end.not_to change(Entry, :count)
        end
      end
    end

    context 'when TELNYX_PUBLIC_KEY is set and signature is invalid' do
      let(:mock_webhook) { instance_double(StandardWebhooks::Webhook) }

      before do
        stub_const('ENV', ENV.to_h.merge('TELNYX_PUBLIC_KEY' => 'test_public_key'))
        allow(StandardWebhooks::Webhook).to receive(:new).and_return(mock_webhook)
        allow(mock_webhook).to receive(:verify).and_raise(StandardError, 'bad sig')
      end

      it 'returns 403 forbidden' do
        post_sms(from: '+15551234567', text: 'Test')
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create an entry' do
        expect do
          post_sms(from: '+15551234567', text: 'Test entry content here')
        end.not_to change(Entry, :count)
      end
    end

    context 'when TELNYX_PUBLIC_KEY is set and signature is valid' do
      let!(:user) { create(:user, phone: '+15551234567', phone_verified: true) }
      let(:mock_webhook) { instance_double(StandardWebhooks::Webhook) }

      before do
        stub_const('ENV', ENV.to_h.merge('TELNYX_PUBLIC_KEY' => 'test_public_key'))
        allow(StandardWebhooks::Webhook).to receive(:new).and_return(mock_webhook)
        allow(mock_webhook).to receive(:verify).and_return(true)
      end

      it 'creates an entry' do
        expect do
          post_sms(from: '+15551234567', text: 'Entry from verified signature here')
        end.to change(Entry, :count).by(1)
      end
    end
  end
end

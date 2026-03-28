# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TwilioWebhooks' do
  describe 'POST /webhooks/twilio' do
    context 'when Twilio is not configured (test environment — signature check skipped)' do
      before do
        allow(TwilioService).to receive(:twilio_configured?).and_return(false)
      end

      context 'when number is not linked to a verified account' do
        it 'returns TwiML with ok status and does not create an entry' do
          expect do
            post '/webhooks/twilio', params: { From: '+15559999999', Body: 'Hello there' }
          end.not_to change(Entry, :count)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Response')
        end
      end

      context 'when number belongs to a verified user' do
        let!(:user) { create(:user, phone: '+15551234567', phone_verified: true) }

        it 'creates an entry and returns TwiML' do
          expect do
            post '/webhooks/twilio',
                 params: { From: '+15551234567', Body: 'Had a great day today in the office' }
          end.to change(user.entries, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('<Response>')
        end

        it 'sets week_start_date to the current Monday' do
          post '/webhooks/twilio',
               params: { From: '+15551234567', Body: 'Had a great day today in the office' }
          expect(user.entries.last.week_start_date).to eq(Date.current.beginning_of_week(:monday))
        end

        it 'does not create an entry when body is too short' do
          post '/webhooks/twilio', params: { From: '+15551234567', Body: 'Hi' }
          expect(user.entries.count).to eq(0)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when body is SKIP (case-insensitive)' do
        let!(:user) { create(:user, phone: '+15551234567', phone_verified: true) }
        let!(:template) { create(:prompt_template) }
        let!(:dispatch) do
          create(:prompt_dispatch,
                 user: user,
                 prompt_template: template,
                 week_start_date: Date.current.beginning_of_week(:monday))
        end

        it 'skips the current week dispatch' do
          post '/webhooks/twilio', params: { From: '+15551234567', Body: 'SKIP' }
          expect(dispatch.reload.status).to eq('skipped')
        end

        it 'also skips when body is lowercase skip' do
          post '/webhooks/twilio', params: { From: '+15551234567', Body: 'skip' }
          expect(dispatch.reload.status).to eq('skipped')
        end

        it 'does not create an entry' do
          expect do
            post '/webhooks/twilio', params: { From: '+15551234567', Body: 'SKIP' }
          end.not_to change(Entry, :count)
        end

        it 'returns TwiML' do
          post '/webhooks/twilio', params: { From: '+15551234567', Body: 'SKIP' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('<Response>')
        end
      end

      context 'when phone is not verified' do
        let!(:user) { create(:user, phone: '+15552223333', phone_verified: false) }

        it 'does not create an entry' do
          expect do
            post '/webhooks/twilio',
                 params: { From: '+15552223333', Body: 'Test entry from unverified number' }
          end.not_to change(Entry, :count)
        end
      end
    end

    context 'when Twilio is configured and signature is invalid' do
      before do
        allow(TwilioService).to receive(:twilio_configured?).and_return(true)
        stub_const('ENV', ENV.to_h.merge('TWILIO_AUTH_TOKEN' => 'test_token'))
        allow_any_instance_of(Twilio::Security::RequestValidator)
          .to receive(:validate).and_return(false)
      end

      it 'returns 403 forbidden' do
        post '/webhooks/twilio',
             params: { From: '+15551234567', Body: 'Test' },
             headers: { 'X-Twilio-Signature' => 'bad_signature' }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create an entry' do
        expect do
          post '/webhooks/twilio',
               params: { From: '+15551234567', Body: 'Test entry content here' },
               headers: { 'X-Twilio-Signature' => 'bad_signature' }
        end.not_to change(Entry, :count)
      end
    end

    context 'when Twilio is configured and signature is valid' do
      let!(:user) { create(:user, phone: '+15551234567', phone_verified: true) }

      before do
        allow(TwilioService).to receive(:twilio_configured?).and_return(true)
        stub_const('ENV', ENV.to_h.merge('TWILIO_AUTH_TOKEN' => 'test_token'))
        allow_any_instance_of(Twilio::Security::RequestValidator)
          .to receive(:validate).and_return(true)
      end

      it 'creates an entry' do
        expect do
          post '/webhooks/twilio',
               params: { From: '+15551234567', Body: 'Entry from verified signature' },
               headers: { 'X-Twilio-Signature' => 'valid_sig' }
        end.to change(Entry, :count).by(1)
      end
    end
  end
end
